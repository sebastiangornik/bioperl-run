# You may distribute this module under the same terms as perl itself
# POD documentation - main docs before the code

=head1 NAME

Bio::Tools::Run::Hmmer - Wrapper for local execution of hmmsearch
,hmmbuild, hmmcalibrate, hmmalign, hmmpfam 

=head1 SYNOPSIS

  #run hmmpfam|hmmalign|hmmsearch
  my $factory = Bio::Tools::Run::Hmmer->new('program'=>'hmmsearch','hmm'=>'model.hmm');

  # Pass the factory a Bio::Seq object or a file name

  # returns a Bio::SearchIO object
  my $search = $factory->run($seq);


  my @feat;
  while (my $result = $searchio->next_result){
   while(my $hit = $result->next_hit){
    while (my $hsp = $hit->next_hsp){
            print join("\t", ( $r->query_name,
                               $hsp->query->start,
                               $hsp->query->end,
                               $hit->name,
                               $hsp->hit->start,
                               $hsp->hit->end,
                               $hsp->score,
                               $hsp->evalue,
                               $hsp->seq_str,
                               )), "\n";
    }
   }
  }

  #build a hmm using hmmbuild
  my $aio = Bio::AlignIO->new(-file=>"protein.msf",-format=>'msf');
  my $aln = $aio->next_aln;
  my $factory =  Bio::Tools::Run::Hmmer->new('program'=>'hmmbuild',
                                             'hmm'=>'model.hmm');
  $factory->run($aln);

  #calibrate the hmm
  my $factory =  Bio::Tools::Run::Hmmer->new('program'=>'hmmcalibrate',
                                             'hmm'=>'model.hmm');
  $factory->run();

  my $factory =  Bio::Tools::Run::Hmmer->new('program'=>'hmmalign',
                                             'hmm'=>'model.hmm');

   # Pass the factory a Bio::Seq object or a file name

   # returns a Bio::AlignIO object
   my $aio = $factory->run($seq);

=head1 DESCRIPTION

Wrapper module for Sean Eddy's  HMMER suite of program to allow running of hmmsearch,hmmpfam,hmmalign, hmmbuild,hmmconvert. Binaries are available at http://hmmer.wustl.edu/

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to one
of the Bioperl mailing lists.  Your participation is much appreciated.

  bioperl-l@bioperl.org                  - General discussion
  http://bioperl.org/wiki/Mailing_lists  - About the mailing lists

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
the bugs and their resolution.  Bug reports can be submitted via the
web:

  http://bugzilla.open-bio.org/

=head1 AUTHOR - Shawn Hoon

 Email: shawnh-at-gmx.net

=head1 CONTRIBUTORS 

 Shawn Hoon shawnh-at-gmx.net
 Jason Stajich jason -at- bioperl -dot- org
 Scott Markel scott -at- scitegic -dot com

=head1 APPENDIX

The rest of the documentation details each of the object
methods. Internal methods are usually preceded with a _

=cut

package Bio::Tools::Run::Hmmer;

use vars qw($AUTOLOAD @ISA @HMMER_PARAMS @HMMER_SWITCHES %DOUBLE_DASH 
            $DefaultOutFormat
            %OK_FIELD);
use strict;
use Bio::SeqIO;
use Bio::Root::Root;
use Bio::SearchIO;
use Bio::AlignIO;
use Bio::Tools::Run::WrapperBase;

@ISA = qw(Bio::Root::Root Bio::Tools::Run::WrapperBase);

BEGIN {
    $DefaultOutFormat = 'msf';
    @HMMER_PARAMS=qw(HMM hmm PROGRAM program DB db A E T Z 
		     outformat null pam prior pbswitch 
		     archpri cfile gapmax idlevel informat pamwgt 
		     swentry swexit withali mapali
		     cpu domE domT
                    );
    @HMMER_SWITCHES=qw(n q oneline f g s fast hand F
		       wblosum wgsc wme wpb wvoronoi wnone noeff 
		       amino nucleic binary pvm xnu null2 acc compat
		       cut_ga cut_nc cut_tc forward
		      );
    %DOUBLE_DASH = map { $_ => 1 } qw(oneline outformat fast hand
		   null pam prior pbswitch amino nucleic
		   binary  wblosum wgsc wme wpb wvoronoi 
		   wnone noeff amino nucleic binary 
		   archpri cfile gapmax idlevel informat 
		   pamwgt swentry swexit cpu
		   mapali withali pvm xnu null2 acc compat
		   cut_ga cut_nc cut_tc forward domeE domT
				     );

    foreach my $attr ( @HMMER_PARAMS,@HMMER_SWITCHES)
                        { $OK_FIELD{$attr}++; }
}

=head2 program_name

 Title   : program_name
 Usage   : $factory>program_name()
 Function: holds the program name
 Returns:  string
 Args    : None

=cut

sub program_name {
  my ($self) = shift;
  return $self->program(@_);
}

=head2 program_dir

 Title   : program_dir
 Usage   : $factory->program_dir(@params)
 Function: returns the program directory, obtiained from ENV variable.
 Returns:  string
 Args    :

=cut

sub program_dir {
  return Bio::Root::IO->catfile($ENV{HMMERDIR}) if $ENV{HMMERDIR};
}

sub AUTOLOAD {
       my $self = shift;
       my $attr = $AUTOLOAD;
       $attr =~ s/.*:://;
       $self->throw("Unallowed parameter: '$attr' !") unless $OK_FIELD{$attr};
       $self->{$attr} = shift if @_;
       return $self->{$attr};
}

=head2 new

 Title   : new
 Usage   : $HMMER->new(@params)
 Function: creates a new HMMER factory
 Returns:  Bio::Tools::Run::HMMER
 Args    : 

=cut

sub new {
       my ($class,@args) = @_;
       my $self = $class->SUPER::new(@args);
       $self->io->_initialize_io();
       my ($attr, $value);
       my %set = ('q' => 0, 'outformat' => '');
       while (@args)  {
           $attr =   shift @args;
           $value =  shift @args;
           next if( $attr =~ /^-/ ); # don't want named parameters
           $self->$attr($value);
	   $set{$attr}++;
       }
       # some hardcoding for the time being
       
       if( $self->program_name =~ /hmmalign/i ) {
	   if( ! $set{'q'} ) { 
	       $self->q(1);
	   } 
	   if( ! $set{'outformat'} ) {
	       $self->outformat($DefaultOutFormat);
	   }
       }
       return $self;
}

=head2 run

 Title   :   run
 Usage   :   $obj->run($seqFile)
 Function:   Runs HMMER and returns Bio::SearchIO
 Returns :   A Bio::SearchIO
 Args    :   A Bio::PrimarySeqI or file name

=cut

sub run{
    my ($self,@seq) = @_;

    if  (ref $seq[0] && $seq[0]->isa("Bio::PrimarySeqI") ){# it is an object
        my $infile1 = $self->_writeSeqFile(@seq);
        return  $self->_run($infile1);
    }
    elsif(ref $seq[0] && $seq[0]->isa("Bio::Align::AlignI")){
        my $infile1 = $self->_writeAlignFile(@seq);
        return  $self->_run($infile1);
    }
    else {
        return  $self->_run(@seq);
    }   
}

=head2 _run

 Title   :   _run
 Usage   :   $obj->_run()
 Function:   Internal(not to be used directly)
 Returns :   An array of Bio::SeqFeature::Generic objects
 Args    :

=cut

sub _run {
    my ($self,$file)= @_;

    my $str = $self->executable;
    my $param_str = $self->arguments." ".$self->_setparams;
    $str.=" $param_str ".$file;

    $self->debug("HMMER command = $str");
    my $progname = $self->program_name;
    if($progname=~ /hmmpfam|hmmsearch/i){
	my $fh;
	open($fh,"$str |") || $self->throw("HMMER call ($str) crashed: $?\n");
	
	return Bio::SearchIO->new(-fh      => $fh, 
				  -verbose => $self->verbose,
				  -format  => "hmmer");
    } elsif ($progname =~ /hmmalign/i ) {
	my $fh;
	open($fh,"$str |") || $self->throw("HMMER call ($str) crashed: $?\n");
	my $alnformat = $self->outformat; # should make this a parameter in the future as cmdline arguments could make this incompatible 
	my $aln = Bio::AlignIO->new(-fh      => $fh,
				    -verbose => $self->verbose,
				    -format  =>$alnformat);

    } else {			
        # for hmmbuild or hmmcalibrate
	my $status = open(OUT,"$str | ");
	my $io;
	while(<OUT>){
	    $io .= $_;
	}
	close(OUT);
	$self->warn($io) if $self->verbose > 0;
	unless( $status ) {
	    $self->throw("HMMER call($str) crashed: $?\n") unless $status==1;
	}
	return 1;
    }
}

=head2 _setparams

 Title   :  _setparams
 Usage   :  Internal function, not to be called directly
 Function:  creates a string of params to be used in the command string
 Example :
 Returns :  string of params
 Args    :  

=cut

sub _setparams {
    my ($self) = @_;
    my $param_string;
    foreach my $attr(@HMMER_PARAMS){
        next if $attr=~/HMM|PROGRAM|DB/i;
        my $value = $self->$attr();
        next unless (defined $value);
        my $attr_key;
        if( $DOUBLE_DASH{$attr} ) {
	    $attr_key = ' --'.$attr;
	} else {
	    $attr_key = ' -'.$attr;
	}
	$param_string .= $attr_key.' '.$value;
    }
    foreach my $attr(@HMMER_SWITCHES){
        my $value = $self->$attr();
        next unless (defined $value);
        my $attr_key;
	if( $DOUBLE_DASH{$attr} ) {
	    $attr_key = ' --'.$attr;
	} else {
	    $attr_key = ' -'.$attr;
	}
        $param_string .= $attr_key;
    }
    my ($hmm) = $self->HMM || $self->DB || $self->throw("Need to specify either HMM file or Database");
    $param_string.=' '.$hmm;

    return $param_string;
}

# hacking to deal with the insanity of autoloading - not sure I like it...-jason
sub hmm {
    my $self = shift;
    $self->HMM(@_);
}
sub db { 
    my $self =shift;
    $self->DB(@_);
}
sub PROGRAM { 
    my $self = shift;
    $self->program(@_);
}

=head2 _writeSeqFile

 Title   :   _writeSeqFile
 Usage   :   obj->_writeSeqFile($seq)
 Function:   Internal(not to be used directly)
 Returns :
 Args    :

=cut

sub _writeSeqFile {
    my ($self,@seq) = @_;
    my ($tfh,$inputfile) = $self->io->tempfile(-dir=>$self->tempdir);
    my $in  = Bio::SeqIO->new(-fh => $tfh , '-format' => 'Fasta');
    foreach my $s(@seq){
	$in->write_seq($s);
    }
    $in->close();
    $in = undef;
    close($tfh);
    undef $tfh;
    return $inputfile;
}

=head2 _writeAlignFile

 Title   :   _writeAlignFile
 Usage   :   obj->_writeAlignFile($seq)
 Function:   Internal(not to be used directly)
 Returns :
 Args    :

=cut

sub _writeAlignFile{
    my ($self,@align) = @_;
    my ($tfh,$inputfile) = $self->io->tempfile(-dir=>$self->tempdir);
    my $in  = Bio::AlignIO->new('-fh'     => $tfh , 
				'-format' => 'msf');
    foreach my $s(@align){
      $in->write_aln($s);
    }
    $in->close();
    $in = undef;
    close($tfh);
    undef $tfh;
    return $inputfile;
}
1;
