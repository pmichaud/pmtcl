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


