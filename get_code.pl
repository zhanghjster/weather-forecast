#!/usr/bin/perl -w
use LWP::UserAgent;
use YAML::XS qw/LoadFile DumpFile/;
use Encode;

# 取得所有地区码, 保存到yml文件

my %LEVEL_NAME = (
	0 => 'Province',#'省',
	1 => 'City', #'市',
	2 => 'Conty', #'区/县'
);

my $level = 0;
my $id    = '';

my $code = {};

&get_code($id, $level, $code);

my $code_file = 'data/code.yml';

DumpFile($code_file, $code);

sub get_code {
	my ($id, $level, $code) = @_;
	
	my $url  = "http://m.weather.com.cn/data5/city$id\.xml";

	print "get $url\n";

	my $UA = LWP::UserAgent->new;
	my $res = $UA->get($url);
	if ($res->is_success) {
		my $content = $res->content;
		if ($level<3) {
			my @array = split(',', $content);
			my $n = 0;
			foreach my $item ( @array ) {
				my ($iid, $name) = split(/\|/, $item);
		
				# set utf8 flag on	
				$name = Encode::decode("utf8", $name);

				if ($level<2) {
					$code->{$iid} ||= {
						name => $name, 
						next_level => {}
					};
					&get_code($iid, $level+1, $code->{$iid}->{next_level}); 
				} else {
					$code->{$iid} = {
						name => $name,
						code => &get_code($iid, $level+1),
					};
				}
			}
		} else {
			my ($code, $name) = split(/\|/, $content);
			return $name;
		}
	} else {
		print "can not get result of $url\n";
	}
}
exit;

