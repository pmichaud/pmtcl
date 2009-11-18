class PmTcl::Compiler is HLL::Compiler;

INIT {
    PmTcl::Compiler.language('PmTcl');
    PmTcl::Compiler.parsegrammar(PmTcl::Grammar);
    PmTcl::Compiler.parseactions(PmTcl::Actions);
}
