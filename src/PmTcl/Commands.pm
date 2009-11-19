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


our sub proc($name, $args, $body) {
    my $parse := 
        PmTcl::Grammar.parse( $body, :rule<body>, :actions(PmTcl::Actions) );
    my $block := $parse.ast;
    my @args  := pir::split(' ', $args);
    for @args {
        if $_ gt '' {
            $block[0].push(
                PAST::Op.new( :pasttype<bind>,
                    PAST::Var.new( :scope<keyed>,
                        PAST::Var.new( :name('lexpad'), :scope<register> ),
                        $_
                    ),
                    PAST::Var.new( :scope<parameter> )
                )
            );
        }
    }
    $block.name($name);
    PAST::Compiler.compile($block);
}


our sub set($varname, $value) {
    our %VARS;
    %VARS{$varname} := $value;
    $value;
}
