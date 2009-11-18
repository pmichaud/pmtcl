INIT { pir::load_bytecode('HLL.pbc'); }

grammar PmTcl::Grammar is HLL::Grammar {
    token TOP { <command> }

    rule command { [<word> ]+ }

    token word { \S+ }
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
}


class PmTcl::Compiler is HLL::Compiler {
    PmTcl::Compiler.language('PmTcl');
    PmTcl::Compiler.parsegrammar(PmTcl::Grammar);
    PmTcl::Compiler.parseactions(PmTcl::Actions);
}

my @ARGS := pir::getinterp__P()[2];
PmTcl::Compiler.command_line(@ARGS);

our sub puts($x) { pir::say($x); ''; }
