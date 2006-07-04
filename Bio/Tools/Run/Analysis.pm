# $Id$
#
# BioPerl module for Bio::Tools::Run::Analysis
#
# Cared for by Martin Senger <martin.senger@gmail.com>
# For copyright and disclaimer see below.
#

# POD documentation - main docs before the code

=head1 NAME

Bio::Tools::Run::Analysis - Module representing any (remote or local)
analysis tool

=head1 SYNOPSIS

  # run analysis 'seqret' using a default location and a default
  # access method (which means using a Web Service at EBI)
  use Bio::Tools::Run::Analysis;
  print new Bio::Tools::Run::Analysis (-name => 'edit::seqret')
       ->wait_for ({ sequence_direct_data => 'tatatacgtatacga',
		     osformat => 'embl'
		     })
       ->result ('outseq');

  # run a longer job without waiting for its completion
  use Bio::Tools::Run::Analysis;
  my $job = new Bio::Tools::Run::Analysis (-name => 'edit::seqret')
                 ->run ({ sequence_direct_data => 'tatatacgtatacga',
		          osformat => 'embl'
		          });
  # ...and after a while
  $job->result ('outseq');

  # get all results in the same invocation (as a hash reference
  # with result names as keys) - let the module decide which
  # results are binary (images in this examples) and save those
  # in file (or files); it also shows how to tell that the module
  # should read input data from a local file first
  use Bio::Tools::Run::Analysis;
  my $results =
    new Bio::Tools::Run::Analysis (-name => 'alignment_multiple::prettyplot')
       ->wait_for ( { msf_direct_data => '@/home/testdata/my.seq' } )
       ->results ('?');
  use Data::Dumper;
  print Dumper ($results);

  # get names, types of all inputs and results,
  # get short and detailed (in XML) service description
  use Bio::Tools::Run::Analysis;
  my $service = new Bio::Tools::Run::Analysis (-name => 'edit::seqret');
  my $hash1 = $service->input_spec;
  my $hash2 = $service->result_spec;
  my $hash3 = $service->analysis_spec;
  my $xml = $service->describe;

  # get current job status
  use Bio::Tools::Run::Analysis;
  print new Bio::Tools::Run::Analysis (-name => 'edit::seqret')
    ->run ( { #...input data...
            } )
    ->status;

  # run a job and print its job ID, keep the job un-destroyed
  use Bio::Tools::Run::Analysis;
  my $job =
    new Bio::Tools::Run::Analysis (-name => 'edit::seqret',
                                   -destroy_on_exit => 0)
    ->run ( { sequence_direct_data => '@/home/testdata/mzef.seq' } );
  print $job->id . "\n";
  # ...it prints (for example):
  #    edit::seqret/c8ef56:ef535489ac:-7ff4

  # ...in another time, on another planet, you may say
  use Bio::Tools::Run::Analysis;
  my $job =
    new Bio::Tools::Run::Analysis::Job (-name => 'edit::seqret',
			                -id => 'edit::seqret/c8ef56:ef535489ac:-7ff4');
  print join ("\n",
	    $job->status,
	    'Finished: ' . $job->ended (1),   # (1) means 'formatted'
            'Elapsed time: ' . $job->elapsed,
	    $job->last_event,
	    $job->result ('outseq')
	    );

  # ...or you may achieve the same keeping module
  # Bio::Tools::Run::Analysis::Job invisible
  use Bio::Tools::Run::Analysis;
  my $job =
    new Bio::Tools::Run::Analysis (-name => 'edit::seqret')
        ->create_job ('edit::seqret/c8ef56:ef535489ac:-7ff4');
  print join ("\n",
	    $job->status,
            # ...
	    );

  # ...and later you may free this job resources
  $job->remove;

  #
  # --- See DESCRIPTION for using generator 'applmaker.pl':
  #


=head1 DESCRIPTION

The module represents an access to the local and/or remote analysis
tools in a unified way that allows adding new access methods
(protocols) seamlessly.

At the moment of writing, there is available a I<SOAP> access to
almost all EMBOSS applications, running at the
European Bioinformatics Institute.

The documentation of all C<public> methods are to be found
in C<Bio::AnalysisI>. A tutorial (and examples how to call almost all
public methods) is in the script C<panalysis.PLS> (go to the C<scripts>
directory and type C<perldoc panalysis.PLS>).

The module C<Bio::Tools::Run::Analysis> uses general approach allowing to set
arbitrary input data and to retrieve results by naming them. However,
sometimes is more convenient to use a specific module, representing
one analysis tool, that already knows about available input and result
names. Such analyses-specific Perl modules can be generated by
C<papplmaker.PLS> generator. Its features and usage are documented in
the generator (go to the C<scripts> directory and type C<perldoc
papplmaker.PLS>).

  # this will generate module Seqret.pm
  perl papplmaker.PLS -n edit.seqret -m Seqret

  # ...which can be used with data-specific methods
  use Seqret;
  my $outseq = new Seqret
    ->sequence_direct_data ('@/home/testdata/my.seq')
    ->osformat ('embl')
    ->wait_for
    ->outseq
    ;
  print $outseq;

=head1 FEEDBACK

=head2 Mailing Lists

User feedback is an integral part of the evolution of this and other
Bioperl modules. Send your comments and suggestions preferably to
the Bioperl mailing list.  Your participation is much appreciated.

  bioperl-l@bioperl.org                  - General discussion
  http://bioperl.org/wiki/Mailing_lists  - About the mailing lists

=head2 Reporting Bugs

Report bugs to the Bioperl bug tracking system to help us keep track
of the bugs and their resolution. Bug reports can be submitted via the
web:

  http://bugzilla.open-bio.org/

=head1 AUTHOR

Martin Senger (martin.senger@gmail.com)

=head1 COPYRIGHT

Copyright (c) 2003, Martin Senger and EMBL-EBI.
All Rights Reserved.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 DISCLAIMER

This software is provided "as is" without warranty of any kind.

=head1 SEE ALSO

=over

=item *

http://www.ebi.ac.uk/soaplab/Perl_Client.html

=back

=head1 APPENDIX

Here is the rest of the object methods.  Internal methods are preceded
with an underscore _.

=cut


# Let the code begin...

package Bio::Tools::Run::Analysis;
use vars qw(@ISA $Revision);
use strict;

use Bio::Root::Root;
use Bio::AnalysisI;
@ISA = qw(Bio::Root::Root Bio::AnalysisI);

BEGIN {
    $Revision = q[$Id$];
}

# -----------------------------------------------------------------------------

=head2 new

 Usage   : my $tool =
             new Bio::Tools::Run::Analysis (-access => 'soap',
                                            -name => 'edit.seqret',
                                            ...
                                            );
 Returns : a new Bio::Tools::Run::Analysis object representing the given tool
 Args    : There may be additional arguments which are specific
           to the access method (see methods 'new' or '_initialize'
           of the access-specific implementations (such as module
	   Bio::Tools::Run::Analysis::soap for a SOAP-based access).

           The recognised and used arguments are:
             -access
             -location
             -name
             -httpproxy
             -timeout

It builds, populates and returns a new C<Bio::Tools::Run::Analysis> object. This
is how it is seen from the outside. But in fact, it builds, populates
and returns a more specific lower-level object, for example
C<Bio::Tools::Run::Analysis::soap> object - which one it depends on the C<-access>
parameter.

=over

=item -access

It indicates what lower-level module to load.  Default is 'soap'.
Other (but future) possibilities may be:

   -access => 'novella'
   -access => 'local'

=item -location

A location of the service. The contents is access-specific (see
details in the lower-level implementation modules).

Default is C<http://www.ebi.ac.uk/soaplab/services> ( services running
at European Bioinformatics Institute on top of most of EMBOSS
analyses, and on few others).

=item -name

A name of an analysis tool, or a name of its higher-level abstraction,
possibly including a category where the analysis belong to. There is
no default value (which usually means that this parameter is mandatory
unless your I<-location> parameter includes also the name (but it is
then access-dependent).

=item -destroy_on_exit =E<gt> '0'

Default value is '1' which means that all Bio::Tools::Run::Analysis::Job
objects - when being finalised - will send a request
to the remote site to forget the results of these jobs.

If you change it to '0' make sure that you know the job identification
- otherwise you will not be able to re-established connection with it
(later, when you use your program again). This can be done by calling
method C<id> on the job object (such object is returned by any of
these methods: C<create_job>, C<run>, C<wait_for>).

=item -httpproxy

In addition to the I<location> parameter, you may need to specify also
a location/URL of an HTTP proxy server (if your site requires
one). The expected format is C<http://server:port>.  There is no
default value. It is also an access-specific parameter which may not
be used by all access methods.

=item -timeout

For long(er) running jobs the HTTP connection may be time-outed. In
order to avoid it (or, vice-versa, to call timeout sooner) you may
specify C<timeout> with the number of seconds the connection will be
kept alive. Zero means to keep it alive forever. The default value is
two minutes.

=back

=cut

sub new {
    my ($caller,@args) = @_;
    my $class = ref($caller) || $caller;
  
    if ($class eq 'Bio::Tools::Run::Analysis') {

	# this is called only the first time when somebody calls: 'new
	# Bio::Tools::Run::Analysis (...)', and it actually loads a 'real-work-doing'
	# module and call this new() method again (unless the loaded
	# module has its own new() method)

	my %param = @args;
	@param { map { lc $_ } keys %param } = values %param; # lowercase keys
	my $access =
	    $param {'-access'} ||                  # use -access parameter
	    &Bio::Tools::Run::Analysis::Utils::_guess_access ( \%param ) ||   # or guess from other parameters
	    'soap';                                # or use a default access method
	$access = "\L$access";	# normalize capitalization to lower case

	# remember the access method (putting it into @args means that the
	# object - when created - will remember it)
	push (@args, (-access => $access)) unless $param {'-access'};

	# load module with the real implementation - as defined in $access
	return undef unless (&Bio::Tools::Run::Analysis::Utils::_load_access_module ($access));

	# this calls this same method new() - but now its object part
	# (see the upper branche above) is called
	return "Bio::Tools::Run::Analysis::$access"->new (@args);

    } else {

	# if $caller is an object, or if it is an underlying
	# 'real-work-doing' class (e.g. Bio::Tools::Run::Analysis::soap) then
	# we want to call SUPER to create and bless a new object

	my ($self) = $class->SUPER::new (@args);

	# now the $self is an empty object - we will populate it from
	# the $caller - if $caller is an object (so we do cloning here)

	if (ref ($caller)) {
	    %{ $self } = %{ $caller };
	}

	# and finally add values from '@args' into the newly created
	# object (the values will overwrite the values copied above);
	# this is done by calling '_initialize' of the 'real-work-doing'
	# class (if there is no one there, there is always an empty one
	# in Bio::Root::Root)

	$self->_initialize (@args);
	return $self;
    }

}

#
# Create a hash with named inputs, all extracted 
# from the given data.
#
sub _prepare_inputs {
    my $self = shift;
    my %inputs = ();   # collect here input data

    foreach my $input (@_) {

	next unless defined $input;

	# an element can be an array reference
	# (with scalar elements: 'name = [[@]value]')
	if (ref $input eq 'ARRAY') {
	    foreach my $elem (@$input) {
		unless (ref $elem) {   # taking only scalars
		    my ($name, $value) = split (/\s*=\s*/, $elem, 2);
		    next unless $name;   # am I paranoid ?
		    $value = 1 unless defined $value;
		    $inputs{$name} = $value;
		    next;
		}
	    }
	}

	# ...or an element can be a hash
	# (name => [@]value)
	elsif (ref $input eq 'HASH') {
	    foreach my $name (keys %$input) {
		my $value = $$input{$name};
		$inputs{$name} = $value;
	    }
	}

	# ...or an element can be a scalar (which means that it
	# represents a name of a boolean parameter (an option)
	elsif (ref \$input eq 'SCALAR') {
	    $input =~ s/^@/\\@/;   # this cannot be a filename
	    $inputs{$input} = 1;
	}

	# everything else is ignored
	else {
	    warn "Unrecognized input data type: $input\n";
	}
    }

    # extracted inputs may be actually filenames and we want the
    # contents of the files instead
    # TBD: to support also filehandlers here?
    foreach my $name (keys %inputs) {
	$inputs{$name} = $self->_read_value ($inputs{$name});
    }
    return \%inputs;
}

# --- if a $value is a filename, read it and return its contents
#     otherwise return the $value itself; if $value start with
#     an escaped '@', change it to a normal '@'
sub _read_value {
    my ($self, $value) = @_;
    return unless defined $value;
    if ($value =~ s/^\@//) {
	my ($buf);
	open (DATA, $value) || $self->throw ("Cannot read from '$value' ($!)");
	binmode (DATA);
	undef $value;
	while (read (DATA, $buf, 8 * 2**10)) {
	    $value .= $buf;
	}
	close DATA;
    } elsif ($value =~ s/^\\\@/@/) {
    }
    $value;
}

# --- save $value of result $name into file $filename + $seq;
#     use some default filename if $filename not given

#$part = $self->_save_result (-value    => $part,
#			      -name     => $name,
#                             -filename => $filename,
#			      -template => $template,
#			      -seq      => $seq++);

sub _save_result {
    my ($self, %params) = @_;
    my $name = $params{'-name'} || 'result';

    # invent filename (if not given) from the given or default template
    my $filename = $params{'-filename'};
    unless ($filename) {
	$filename = $params{'-template'};
	$filename = "\$ANALYSIS_*_$name" unless $filename;

	# replace $ANALYSIS and $RESULT in the filename
	if ($filename =~ /\$\{?ANALYSIS\}?/) {
	    # (better to ask if we need it because getting
	    #  the analysis name may require going to server)
	    my $analysis = $self->analysis_name;
	    $analysis =~ s/[:\/]/_/g;  # would be troubles in filename
	    $filename =~ s/\$\{?ANALYSIS\}?/$analysis/ig;
	}
	$filename =~ s/\$\{?RESULT\}?/$name/ig;
    }

    # include the sequential number before file extension (if any)
    my $seq = $params{'-seq'};
    if ($seq) {
	my $pos = rindex ($filename, '.');
	if ($pos > -1) {
	    substr ($filename, $pos, 0) = ".$seq";   # insert $seq
	} else {
            $filename .= ".$seq";   # add $seq
	}
    }

    # replace '*' in filename with a unique number
    while ($filename =~ /\*/) {
        my $unique_name;
	my $number = 1;
	while (1) {
	    ($unique_name = $filename) =~ s/\*/$number/;
	    last unless -e $unique_name;
	    $number++;
	}
	$filename = $unique_name;
    }

    # and finally write the file
    open (DATA, ">$filename") ||
	$self->throw ("Error by saving result '$name' into '$filename' ($!)");
    binmode (DATA);
    print (DATA $params{'-value'}) ||
	$self->throw ("Error by writing result '$name' into '$filename' ($!)");
    close DATA ||
	$self->throw ("Error by closing result '$name' in '$filename' ($!)");

    return $filename;
}


=head2 VERSION and Revision

 Usage   : print $Bio::Tools::Run::Analysis::VERSION;
           print $Bio::Tools::Run::Analysis::Revision;

=cut

# -----------------------------------------------------------------------------
# Bio::Tools::Run::Analysis::Job
#    A module representing an invocation (execution, job) of an analysis.
# -----------------------------------------------------------------------------

package Bio::Tools::Run::Analysis::Job;

=head1 Module Bio::Tools::Run::Analysis::Job

It represents a job, a single execution of an analysis tool. Usually
you do not instantiate these objects - they are returned by methods
C<create_job>, C<run>, and C<wait_for> of C<Bio::Tools::Run::Analysis> object.

However, if you wish to re-create a job you need to know its ID
(method C<id> gives it to you). The ID can be passed directly to the
C<new> method, or again you may use C<create_job> of a
C<Bio::Tools::Run::Analysis> object with the ID as parameter. See SYNOPSIS above
for an example.

Remember that all public methods of this module are described in
details in interface module C<Bio::AnalysisI> and in the tutorial in
the C<analysis.pl> script.

=cut


use vars qw(@ISA);
use strict;

use Bio::Root::Root;
@ISA = qw(Bio::Root::Root Bio::AnalysisI::JobI);

# -----------------------------------------------------------------------------

=head2 new

 Usage   : my $job = new Bio::Tools::Run::Analysis::Job
                       (-access => 'soap',
                        -name => 'edit.seqret',
                        -id => 'xxxyyy111222333'
                        );
 Returns : a re-created object representing a job
 Args    : The same arguments as for Bio::Tools::Run::Analysis object:
             -access
             -location
             -name
             -httpproxy
             -timeout
             (and perhaps others)
           Additionally and specifically for this object:
             -id
             -analysis

=over

=item -id

A job ID created some previous time and now used to re-create the same
job (in order to re-gain access to this job results, for example).

=item -analysis

A C<Bio::Tools::Run::Analysis> object whose properties (such as C<-access> and
C<-location> are used to re-create this job object.

=back

=cut

sub new {
    my ($caller, @args) = @_;
    my $class = ref($caller) || $caller;
  
    if ($class eq 'Bio::Tools::Run::Analysis::Job') {

	# this is called only the first time when somebody calls:
	#'new Bio::Tools::Run::Analysis::Job (...)'

	my %param = @args;
	@param { map { lc $_ } keys %param } = values %param; # lowercase keys
	if ($param {'-analysis'}) {

	    # usually a new Job object is created from an existing
	    # Analysis object - which means that the Analysis already
	    # loaded a 'real-work-doing' Job object, so we need just
	    # to create a Job object (by calling its new() method,
	    # which calls actually this new() method again - but its
	    # 'object' part - see below

	    my $analysis = $param {'-analysis'};
	    return undef unless $analysis->{'_access'};  # TBD: error message here?
	    my $access = $analysis->{'_access'};
	    return "Bio::Tools::Run::Analysis::Job::$access"->new (@args);

	} else {

	    # if a new Job object is created directly (by a user, not
	    # by a parent Analysis object) we need to create the
	    # Analysis object first (because it is the Analysis object
	    # who knows how to contact the underlying analysis tool),
	    # and only then let the Analysis create this Job object
	    # (which may be an empty Job - if there is no 'id' in @args)

	    return new Bio::Tools::Run::Analysis (@args)->create_job ($param {'-id'});
	}

    } else {

	# if $caller is an object, or if it is an underlying
	# 'real-work-doing' class (e.g. Bio::Tools::Run::Analysis::Job::soap) then
	# we want to call SUPER to create and bless a new object

	my ($self) = $class->SUPER::new (@args);

	# now the $self is an empty object - we will populate it from
	# the $caller - if $caller is an object (so we do cloning here)

	if (ref ($caller)) {
	    %{ $self } = %{ $caller };
	}

	# and finally add values from '@args' into the newly created
	# object (the values will overwrite the values copied above);
	# this is done by calling '_initialize' of the 'real-work-doing'
	# class (if there is no one there, there is always an empty one
	# in Bio::Root::Root)

	$self->_initialize (@args);
	return $self;
    }

}

sub id { shift->{'_id'}; }

# ---------------------------------------------------------------------
#
#   A Utility module...
#
# ---------------------------------------------------------------------

package Bio::Tools::Run::Analysis::Utils;

=head1 Module Bio::Tools::Run::Analysis::Utils

It contains several general utilities. These are C<functions>, not
methods. Therefore call them like, for example:

    &Bio::Tools::Run::Analysis::Utils::format_time (...);

=cut

# -----------------------------------------------------------------------------

=head2 format_time

 Usage   : Bio::Tools::Run::Analysis::Utils::format_time ($time);
 Returns : Slightly formatted $time
 Args    : $time is number of seconds from the beginning of Epoch

It returns what C<localtime> returns which means that return value is
different in the array and scalar context (see localtime). If C<$time>
is ``-1'' it returns 'n/a' (in the scalar context) or an empty array
(in the array context). If C<$time> is too small to represent the
distance from the beginning of the Epoch, it returns it unchanged (the
same in any contex) - this is reasonable for C<$time> representing an
elapsed time.

The function is used to format times coming back from various job time
methods.

=cut

sub format_time {
    my $time = shift;
    return wantarray ? () : 'n/a' if "$time" eq '-1';
    return $time if $time < 1000000000;
    return localtime $time;
}

# -----------------------------------------------------------------------------

# It processes given result names which may be of various different
# types and returns a hash reference with result names as keys and
# values being result destinations (such as file names, or templates
# how to create filenames.
#
# Or, it returns a scalar ('@[template]' or '?[template]') if there
# were no real result names but only a global rule how to create
# result destinantions for all results.
#
# Or, it returns 'undef' if there were no result names at all.

sub normalize_names {
    return undef unless @_;
    my %names = ();
    foreach (@_) {
	if (ref $_ eq 'HASH') {
	    %names = (%names, %$_);
	} elsif (not ref $_) {
	    my ($name, $dest) = split (/\s*=\s*/, $_, 2);
	    return $name if $name =~ /^@/;  # special: it nullifies other rules
	    return $name if $name =~ /^\?/; # ditto
	    $names{$name} = $dest;   # $dest may be undef
	}
    }
    \%names;
}

# -----------------------------------------------------------------------------

=head2 _load_access_module

 Usage   : $class->_load_access_module ($access)
 Returns : 1 on success, undef on failure
 Args    : 'access' should contain the last part of the
           name of a module who does the real implementation

It does (in the run-time) a similar thing as

   require Bio::Tools::Run::Analysis::$access

It prints an error on STDERR if it fails to find and load the module
(for example, because of the compilation errors in the module).

=cut

sub _load_access_module {
  my ($access) = @_;

  my $load = "Bio/Tools/Run/Analysis/$access.pm";
  eval {
    require $load;
  };

  if ( $@ ) {
    Bio::Root::Root->throw (<<END);
$load: $access cannot be found or loaded
Exception $@
For more information about the Analysis system please see the Bio::Tools::Run::Analysis docs.
END
  ;
    return;
  }
  return 1;
}

# -----------------------------------------------------------------------------

=head2 _guess_access

 Usage   : Bio::Tools::Run::Analysis::Utils::guess_access ($rh_params)
 Returns : string with a guessed access protocol (e.g. 'soap'),
           or undef if the guessing failed
 Args    : 'rh_params' is a hash reference containing parameters given
           to the 'new' method.

It makes an expert guess what kind of access/transport protocol should
be used to access the underlying analysis. The guess is based on the
parameters in I<rh_params>. Rememeber that this method is called only
if there was no I<-access> parameter which could tell directly what
access method to use.

=cut

sub _guess_access {
   my ($rh_params) = @_;
   return undef;
}



1;
__END__
