use File::Find;
use File::Spec;

# Get the username
my $username = $ENV{LOGNAME} || $ENV{USER} || getpwuid($<);

# Set the main file
@default_files = ('index.tex');

if ($username eq "keri") {
    # Set Skim as the default PDF previewer
    $pdf_previewer = 'open -a Skim %S';

    # Enable Preview Continuous Mode
    $preview_continuous_mode = 1;
}

# Generate a PDF using pdfLaTeX
$pdf_mode = 1;

# Use batchmode
set_tex_cmds('--interaction=batchmode %O %S');

# Add to the list of generated extensions
push @generated_exts, "fdb_latexmk";
push @generated_exts, "fls";
push @generated_exts, "hd";
push @generated_exts, "tex.lhs";
push @generated_exts, "ptb";
push @generated_exts, "vtc";

# Run bibtex
$bibtex_use = 2;

# Set the auxiliary and output directories
$aux_dir = "build";

# Always view the file via a temporary file
$always_view_file_via_temporary = 1;

# Always analyze the log file
$analyze_input_log_always = 1;

# Ensure that the custom dependencies are cleaned up
$cleanup_includes_cusdep_generated = 1;

# Add the assets directory to the TEXINPUTS environment variable
ensure_path('TEXINPUTS', './assets//');

# Use Makefile to make missing files:
# $use_make_for_missing_files = 1;

# Add Pandoc and lhs2TeX as a custom dependency
unless (defined $ENV{SKIP_CUS_DEP}) {
  add_cus_dep('md', 'tex', 0, 'run_pandoc_and_lhs2TeX');
}
sub run_pandoc_and_lhs2TeX {
  my $base = shift @_;

  if ($base eq 'index') {
    # Get sources for custom dependency
    my @sources;
    ## Assets
    push @sources, './assets/preamble.fmt';
    push @sources, './assets/preamble.tex';
    push @sources, './assets/templates/acmart.tex';
    ## Scripts
    find(sub {
        return unless -f;
        return unless /\.lua$/;
        push @sources, $File::Find::name;
    }, "./filters");
    ## Configuration
    push @sources, './assets/defaults.yaml';
    push @sources, $base;

    # Set sources for custom dependency
    rdb_set_source($rule, @sources);

    # Run Pandoc
    my $pandoc_exit_code = system('pandoc', '-d', 'assets/defaults.yaml', "$base.md", '-o', "$base.tex.lhs");

    # If Pandoc succeeded...
    if ($pandoc_exit_code eq 0) {
        # ...run lhs2TeX
        return system('lhs2TeX', "$base.tex.lhs", '-o', "$base.tex");
    } else {
        # ...otherwise, fail
        return $pandoc_exit_code
    }
  };
}
