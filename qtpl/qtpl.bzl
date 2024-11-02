"""Rules for expanding github.com/valyala/quicktemplate templates."""

load("@rules_go//go:def.bzl", "go_context")

def _qtpl_gen_actions(ctx, src):
    copied = ctx.actions.declare_file(src.basename)
    ctx.actions.run_shell(
        inputs = [src],
        outputs = [copied],
        arguments = [src.path, copied.path],
        command = "cp $1 $2",
        mnemonic = "QtplSrcCopy",
    )

    generated = ctx.actions.declare_file(src.basename + ".go")
    ctx.actions.run(
        inputs = [copied],
        outputs = [generated],
        arguments = ["-file", copied.path],
        executable = ctx.executable._qtpl_compiler,
        mnemonic = "QtplCompile",
    )

    return generated

def _go_qtpl_impl(ctx):
    go = go_context(ctx)

    outputs = []
    for src in ctx.files.srcs:
        outputs.append(_qtpl_gen_actions(ctx, src))

    # This seems magic, but rules_go apparently just does the right thing here
    lib = go.new_library(
        go = go,
        importable = True,
        srcs = outputs,
        deps = ctx.attr.deps + ctx.attr._qtpl_deps,
        importpath = ctx.attr.importpath,
    )
    src = go.library_to_source(go, {}, lib, ctx.coverage_instrumented())
    archive = go.archive(
        go = go,
        source = src,
    )

    return [
        archive,
        lib,
        src,
        DefaultInfo(
            files = depset(outputs + [archive.data.file]),
            runfiles = archive.runfiles,
        ),
    ]

go_qtpl_library = rule(
    implementation = _go_qtpl_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = [".qtpl"],
            mandatory = True,
        ),
        "deps": attr.label_list(
            # TODO(scott): Limit to Go libraries
        ),
        "importpath": attr.string(),
        "_go_context_data": attr.label(
            default = "@rules_go//:go_context_data",
        ),
        "_qtpl_deps": attr.label_list(
            default = ["@com_github_valyala_quicktemplate//:quicktemplate"],
        ),
        "_qtpl_compiler": attr.label(
            default = "@com_github_valyala_quicktemplate//qtc",
            executable = True,
            cfg = "exec",
        ),
    },
    toolchains = ["@rules_go//go:toolchain"],
)
