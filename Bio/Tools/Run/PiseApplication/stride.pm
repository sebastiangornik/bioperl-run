
=head1 NAME

Bio::Tools::Run::PiseApplication::stride

=head1 SYNOPSIS

=head1 DESCRIPTION

Bio::Tools::Run::PiseApplication::stride

      Bioperl class for:

	STRIDE	Protein secondary structure assignment from atomic coordinates (D. Frishman & P. Argos)

	References:

		Frishman D, Argos P. Knowledge-based protein secondary structure assignment. Proteins. 1995 Dec;23(4):566-79.


      Parameters:


		stride (String)
			

		pdbfile (Sequence)
			PDB File

		pdbid (String)
			or you can instead enter a PDB id.

		control (Paragraph)
			Control parameters

		read_chain (String)
			Read only these chains (-r)

		process_chain (String)
			Process only these chains (-c)

		output (Paragraph)
			Output parameters

		molscript (Switch)
			Generate a Molscript file (-m)

		ss_only (Switch)
			Report secondary structure summary Only (-o)

		hydrogen (Switch)
			Report Hydrogen bonds (-h)

		fasta (Switch)
			Generate SeQuence file in FASTA format (-q)

		molscript_file (Results)
			

		outfile (Results)
			
			pipe: stride_outfile

=cut

#'
package Bio::Tools::Run::PiseApplication::stride;

use vars qw(@ISA);
use strict;
use Bio::Tools::Run::PiseApplication;

@ISA = qw(Bio::Tools::Run::PiseApplication);

=head2 new

 Title   : new()
 Usage   : my $stride = Bio::Tools::Run::PiseApplication::stride->new($remote, $email, @params);
 Function: Creates a Bio::Tools::Run::PiseApplication::stride object.
           This method should not be used directly, but rather by 
           a Bio::Factory::Pise instance:
           my $factory = Bio::Factory::Pise->new(-email => 'me@myhome');
           my $stride = $factory->program('stride');
 Example :
 Returns : An instance of Bio::Tools::Run::PiseApplication::stride.

=cut

sub new {
    my ($class, $remote, $email, @params) = @_;
    my $self = $class->SUPER::new($remote, $email);

# -- begin of definitions extracted from /local/gensoft/lib/Pise/5.a/PerlDef/stride.pm

    $self->{COMMAND}   = "stride";
    $self->{VERSION}   = "5.a";
    $self->{TITLE}   = "STRIDE";

    $self->{DESCRIPTION}   = "Protein secondary structure assignment from atomic coordinates";

    $self->{AUTHORS}   = "D. Frishman & P. Argos";

    $self->{REFERENCE}   = [

         "Frishman D, Argos P. Knowledge-based protein secondary structure assignment. Proteins. 1995 Dec;23(4):566-79.",
 ];

    $self->{_INTERFACE_STANDOUT} = undef;
    $self->{_STANDOUT_FILE} = undef;

    $self->{TOP_PARAMETERS}  = [ 
	"stride",
	"pdbfile",
	"pdbid",
	"control",
	"output",
	"molscript_file",
	"outfile",

    ];

    $self->{PARAMETERS_ORDER}  = [
	"stride",
	"pdbfile", 	# PDB File
	"pdbid", 	# or you can instead enter a PDB id.
	"control", 	# Control parameters
	"read_chain", 	# Read only these chains (-r)
	"process_chain", 	# Process only these chains (-c)
	"output", 	# Output parameters
	"molscript", 	# Generate a Molscript file (-m)
	"ss_only", 	# Report secondary structure summary Only (-o)
	"hydrogen", 	# Report Hydrogen bonds (-h)
	"fasta", 	# Generate SeQuence file in FASTA format (-q)
	"molscript_file",
	"outfile",

    ];

    $self->{TYPE}  = {
	"stride" => 'String',
	"pdbfile" => 'Sequence',
	"pdbid" => 'String',
	"control" => 'Paragraph',
	"read_chain" => 'String',
	"process_chain" => 'String',
	"output" => 'Paragraph',
	"molscript" => 'Switch',
	"ss_only" => 'Switch',
	"hydrogen" => 'Switch',
	"fasta" => 'Switch',
	"molscript_file" => 'Results',
	"outfile" => 'Results',

    };

    $self->{FORMAT}  = {
	"stride" => {
		"seqlab" => 'stride',
		"perl" => '"stride"',
	},
	"pdbfile" => {
		"perl" => '($pdbid)? " $pdbid.pdb" : " $value"',
	},
	"pdbid" => {
		"perl" => '(($pdbid =~ tr/A-Z/a-z/) || $value)? "cat `pdbloc $pdbid` > $pdbid.pdb ; " : "" ',
	},
	"control" => {
	},
	"read_chain" => {
		"perl" => '($value)? " -r$value" : "" ',
	},
	"process_chain" => {
		"perl" => '($value)? " -c$value" : "" ',
	},
	"output" => {
	},
	"molscript" => {
		"perl" => ' ($value)? " -m$pdbfile.mol" : "" ',
	},
	"ss_only" => {
		"perl" => ' ($value)? " -o":""',
	},
	"hydrogen" => {
		"perl" => ' ($value)? " -h" : "" ',
	},
	"fasta" => {
		"perl" => ' ($value)? " -q" : "" ',
	},
	"molscript_file" => {
	},
	"outfile" => {
	},

    };

    $self->{FILENAMES}  = {
	"molscript_file" => '*.mol',
	"outfile" => '*.out',

    };

    $self->{SEQFMT}  = {

    };

    $self->{GROUP}  = {
	"stride" => 0,
	"pdbfile" => 10,
	"pdbid" => -10,
	"read_chain" => 1,
	"process_chain" => 1,
	"molscript" => 1,
	"ss_only" => 1,
	"hydrogen" => 1,
	"fasta" => 1,

    };

    $self->{BY_GROUP_PARAMETERS}  = [
	"pdbid",
	"stride",
	"molscript_file",
	"control",
	"output",
	"outfile",
	"process_chain",
	"molscript",
	"ss_only",
	"hydrogen",
	"fasta",
	"read_chain",
	"pdbfile",

    ];

    $self->{SIZE}  = {

    };

    $self->{ISHIDDEN}  = {
	"stride" => 1,
	"pdbfile" => 0,
	"pdbid" => 0,
	"control" => 0,
	"read_chain" => 0,
	"process_chain" => 0,
	"output" => 0,
	"molscript" => 0,
	"ss_only" => 0,
	"hydrogen" => 0,
	"fasta" => 0,
	"molscript_file" => 0,
	"outfile" => 0,

    };

    $self->{ISCOMMAND}  = {
	"stride" => 1,
	"pdbfile" => 0,
	"pdbid" => 0,
	"control" => 0,
	"read_chain" => 0,
	"process_chain" => 0,
	"output" => 0,
	"molscript" => 0,
	"ss_only" => 0,
	"hydrogen" => 0,
	"fasta" => 0,
	"molscript_file" => 0,
	"outfile" => 0,

    };

    $self->{ISMANDATORY}  = {
	"stride" => 0,
	"pdbfile" => 0,
	"pdbid" => 0,
	"control" => 0,
	"read_chain" => 0,
	"process_chain" => 0,
	"output" => 0,
	"molscript" => 0,
	"ss_only" => 0,
	"hydrogen" => 0,
	"fasta" => 0,
	"molscript_file" => 0,
	"outfile" => 0,

    };

    $self->{PROMPT}  = {
	"stride" => "",
	"pdbfile" => "PDB File",
	"pdbid" => "or you can instead enter a PDB id.",
	"control" => "Control parameters",
	"read_chain" => "Read only these chains (-r)",
	"process_chain" => "Process only these chains (-c)",
	"output" => "Output parameters",
	"molscript" => "Generate a Molscript file (-m)",
	"ss_only" => "Report secondary structure summary Only (-o)",
	"hydrogen" => "Report Hydrogen bonds (-h)",
	"fasta" => "Generate SeQuence file in FASTA format (-q)",
	"molscript_file" => "",
	"outfile" => "",

    };

    $self->{ISSTANDOUT}  = {
	"stride" => 0,
	"pdbfile" => 0,
	"pdbid" => 0,
	"control" => 0,
	"read_chain" => 0,
	"process_chain" => 0,
	"output" => 0,
	"molscript" => 0,
	"ss_only" => 0,
	"hydrogen" => 0,
	"fasta" => 0,
	"molscript_file" => 0,
	"outfile" => 0,

    };

    $self->{VLIST}  = {

	"control" => ['read_chain','process_chain',],
	"output" => ['molscript','ss_only','hydrogen','fasta',],
    };

    $self->{FLIST}  = {

    };

    $self->{SEPARATOR}  = {

    };

    $self->{VDEF}  = {
	"molscript" => '0',
	"ss_only" => '0',
	"hydrogen" => '0',
	"fasta" => '0',

    };

    $self->{PRECOND}  = {
	"stride" => { "perl" => '1' },
	"pdbfile" => { "perl" => '1' },
	"pdbid" => { "perl" => '1' },
	"control" => { "perl" => '1' },
	"read_chain" => { "perl" => '1' },
	"process_chain" => { "perl" => '1' },
	"output" => { "perl" => '1' },
	"molscript" => { "perl" => '1' },
	"ss_only" => { "perl" => '1' },
	"hydrogen" => { "perl" => '1' },
	"fasta" => { "perl" => '1' },
	"molscript_file" => {
		"perl" => '$molscript',
	},
	"outfile" => { "perl" => '1' },

    };

    $self->{CTRL}  = {
	"pdbfile" => {
		"perl" => {
			'! ($pdbid || $pdbfile)' => "You must enter either the PDB data or the PDB id",
		},
	},

    };

    $self->{PIPEOUT}  = {
	"outfile" => {
		 '1' => "stride_outfile",
	},

    };

    $self->{WITHPIPEOUT}  = {

    };

    $self->{PIPEIN}  = {

    };

    $self->{WITHPIPEIN}  = {

    };

    $self->{ISCLEAN}  = {
	"stride" => 0,
	"pdbfile" => 0,
	"pdbid" => 0,
	"control" => 0,
	"read_chain" => 0,
	"process_chain" => 0,
	"output" => 0,
	"molscript" => 0,
	"ss_only" => 0,
	"hydrogen" => 0,
	"fasta" => 0,
	"molscript_file" => 0,
	"outfile" => 0,

    };

    $self->{ISSIMPLE}  = {
	"stride" => 1,
	"pdbfile" => 1,
	"pdbid" => 1,
	"control" => 0,
	"read_chain" => 0,
	"process_chain" => 0,
	"output" => 0,
	"molscript" => 0,
	"ss_only" => 0,
	"hydrogen" => 0,
	"fasta" => 0,
	"molscript_file" => 0,
	"outfile" => 0,

    };

    $self->{PARAMFILE}  = {

    };

    $self->{COMMENT}  = {
	"read_chain" => [
		"Example: AB",
		"=> calculate secondary structure assignment for chains A and B only.",
	],
	"process_chain" => [
		"Process only chains Id1, Id2 ...etc. Secondary structure assignment will be produced only for these chains, but other chains that are present will be taken into account while calculating residue accessible surface and detecting inter-chain hydrogen bonds and, possibly, interchain beta-sheets. By default all protein chains read are processed.",
		"Examples: ",
		"Process only = ABC and Read only = C",
		"=> calculate secondary structure assignment for chain C in the presence of chains A and B.",
	],

    };

    $self->{SCALEMIN}  = {

    };

    $self->{SCALEMAX}  = {

    };

    $self->{SCALEINC}  = {

    };

    $self->{INFO}  = {

    };

# -- end of definitions extracted from /local/gensoft/lib/Pise/5.a/PerlDef/stride.pm



    $self->_init_params(@params);

    return $self;
}



1; # Needed to keep compiler happy

