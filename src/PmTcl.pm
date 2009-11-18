INIT { pir::load_bytecode('HLL.pbc'); }

grammar PmTcl::Grammar is HLL::Grammar {
    token TOP { <command> }

    token command { [ <.ws> <word> ]+ }

    token word { 
       :my $*IN_QUOTE := 0;
       [
       | <WORD=braced_word>
       | <WORD=quoted_word>
       | <WORD=compound_word>
       ]
    }

    token braced_word { '{' $<val>=[<-[}]>*] '}' }
    token quoted_word { '"' :my $*IN_QUOTE := 1; <compound_word> '"' }

    token compound_word { <word_atom>+ }
   
    proto token word_atom { <...> }
    token word_atom:sym<$>    { <variable> }
    token word_atom:sym<[ ]>  { '[' ~ ']' <command> }
    token word_atom:sym<bare> { <-barestopper>+ }
    token word_atom:sym<nl>   { '\n' }
    token word_atom:sym<backslash> { \\ $<chr>=[.] }
    token word_atom:sym<ws>   { \s+ <?{ $*IN_QUOTE }> }

    token identifier { <ident> ** '::' }
    token variable { '$' <identifier> }

    token barestopper { \s | <[ \\ \$ \[ \] ]> | \" <?{ $*IN_QUOTE }> }

    # expression parsing

    INIT {
        PmTcl::Grammar.O(':prec<13>', '%multiplicative');
        PmTcl::Grammar.O(':prec<12>', '%additive');
    }

    token term:sym<integer> { <integer> }
    token term:sym<variable> { <variable> }

    token infix:sym<*> { <sym> <O('%multiplicative, :pirop<mul>')> }
    token infix:sym</> { <sym> <O('%multiplicative, :pirop<div>')> }

    token infix:sym<+> { <sym> <O('%additive, :pirop<add>')> }
    token infix:sym<-> { <sym> <O('%additive, :pirop<sub>')> }

}


class PmTcl::Actions is HLL::Actions {
    method TOP($/) { make $<command>.ast; }

    method command($/) {
        my $past := PAST::Op.new( :name(~$<word>[0].ast), :node($/) );
        my $i := 1;
        my $n := +$<word>;
        while $i < $n {
            $past.push($<word>[$i].ast);
            $i++;
        }
        make $past;
    }

    method word($/) { make $<WORD>.ast; }

    method braced_word($/) { make ~$<val>; }
    method quoted_word($/) { make $<compound_word>.ast; }

    method compound_word($/) {
        my @parts;
        my $lastlit := '';
        for $<word_atom> {
            my $ast := $_.ast;
            if !PAST::Node.ACCEPTS($ast) {
                $lastlit := $lastlit ~ $ast;
            }
            else {
                if $lastlit gt '' { @parts.push($lastlit); }
                @parts.push($ast);
                $lastlit := '';
            }
        }
        if $lastlit gt '' { @parts.push($lastlit); }
        my $past := @parts ?? @parts.shift !! '';
        while @parts {
            $past := PAST::Op.new( $past, @parts.shift, :pirop<concat>);
        }
        make $past;
    }

    method word_atom:sym<$>($/)         { make $<variable>.ast; }
    method word_atom:sym<[ ]>($/)       { make $<command>.ast; }
    method word_atom:sym<bare>($/)      { make ~$/; }
    method word_atom:sym<nl>($/)        { make "\n"; }
    method word_atom:sym<backslash>($/) { make ~$<chr>; }
    method word_atom:sym<ws>($/)        { make ~$/; }

    method variable($/) {
        make PAST::Var.new( :scope<keyed>,
                 PAST::Var.new( :name('%VARS'), :scope<package> ),
                 ~$<identifier>,
                 :node($/)
             );
    }

    method term:sym<variable>($/) { make $<variable>.ast; }
    method term:sym<integer>($/) { make $<integer>.ast; }
}


class PmTcl::Compiler is HLL::Compiler {
    PmTcl::Compiler.language('PmTcl');
    PmTcl::Compiler.parsegrammar(PmTcl::Grammar);
    PmTcl::Compiler.parseactions(PmTcl::Actions);
}

my @ARGS := pir::getinterp__P()[2];
PmTcl::Compiler.command_line(@ARGS);

our sub puts($x) { pir::say($x); ''; }

our sub expr(*@args) { 
    my $parse := 
        PmTcl::Grammar.parse(
            pir::join(' ', @args), 
            :rule('EXPR'),
            :actions(PmTcl::Actions) 
        );
    PAST::Compiler.eval(PAST::Block.new($parse.ast));
}

our sub set($varname, $value) {
    our %VARS;
    %VARS{$varname} := $value;
    $value;
}


