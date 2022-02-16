use strict; 
use warnings; 

open(my $full, "<", "Lexique383.tsv");  
open(my $simple, "+>", "simple_lex.tsv");

## Ecrit les deux premières colonnes dans un nouveau fichier avec quelques modifications
<$full>; #passe la 1ère ligne (noms de colonnes)
while(my $ligne = <$full>){
	chomp($ligne);
	my @info = split(/\t/, $ligne);
	my $voy = "aeiouEO3y\@5§129";
	$info[1] =~ s/°/3/g;					#E muets
	if ($info[0] =~ /ou([aeiouéèâîû])/) {	#ou + voyelle
		$info[1] =~ s/w([$voy])/u$1/;
	}
	if ($info[0] =~ /osses?$/) {
		$info[1] =~ s/os$/Os/;
	}
	print($simple "$info[0]\t$info[1]\n");
}

close($full);
close($simple);