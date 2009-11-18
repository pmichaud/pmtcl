INIT { pir::load_bytecode('HLL.pbc'); }

grammar PmTcl::Grammar is HLL::Grammar {
    token TOP { <command> }

    token command { [ <.ws> <word> ]+ }

    token word { \S+ }

    INIT {
        PmTcl::Grammar.O(':prec<13>', '%multiplicative');
        PmTcl::Grammar.O(':prec<12>', '%additive');
    }

    token term:sym<integer> { <integer> }

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

    method word($/) { make ~$/; }

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
    pir::say(PAST::Compiler.eval(PAST::Block.new($parse.ast)));
}

