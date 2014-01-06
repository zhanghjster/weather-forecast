#!/usr/bin/perl
use LWP::UserAgent;
use YAML::XS qw/LoadFile DumpFile/;
use JSON::XS;
use JSON;
use Encode;
use Getopt::Long;
use utf8;
use vars qw($name $code);
use Data::Dumper;
$Data::Dumper::Useperl = 1;

# API, pick anyone you like, $code is the one get from get_code.pl
# http://www.weather.com.cn/data/sk/$code.html 
# http://www.weather.com.cn/data/cityinfo/$code.html 
# http://m.weather.com.cn/data/$code.html  

GetOptions(
	'name=s' => \$name, # 中文地址名称，精确到区县
	'code=s' => \$code, # 在get_code.pl中输入的地址码表
);

unless ($name || $code) {
	die "Please input 'code' or 'name'\n";
}

if ($name) {
	my $code_hash = LoadFile('data/code.yml');
	
	while (my ($id, $v1) = each %$code_hash) {
		while (my ($id, $v2) = each %{$v1->{next_level}}) {
			while (($id, $v3) = each %{$v2->{next_level}}) {
				# because $name inputed from STDIN is utf8 flag off
				# $v3->{name} is utf8 flag on, have to turn it off when do eq
				$v3->{name} = Encode::encode("utf8", $v3->{name});
				if ($name eq $v3->{name}) {
					$code = $v3->{code};
				}
			}
		}
	}
}

die "can not found the weather code\n" unless $code;

my $api = "http://m.weather.com.cn/data/$code\.html";
my $UA  = LWP::UserAgent->new;
my $res = $UA->get($api);
if ($res->is_success) {
	# utf8 with utf8 flag off 
	my $str = $res->content;

	$hash = from_json($str);

	# If you want to Dumper chinese string
	# need every strings utf8 flag off
	# and set $Data::Dumper::Useperl = 1
	# so we have to use from_json do it automatically	
	print Dumper($hash);

	# IF want to save to yml, must turn utf8 flag on for every string
	# because DumpFile set FILEHANDLE binmode utf8 on
	# $hash = from_json(Encode::decode('utf8', $str));
	# DumpFile("weather.yml", $hash);

	# print formatted json content
	# my $json = JSON::XS->new->utf8->pretty(1)->encode($hash);
	# print $json."\n";	
} else {
	die "can not get $api\n";
}

