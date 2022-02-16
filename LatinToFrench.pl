#============================================================
# Script : LatinToFrench.pl
# Auteur : Camille Pirali
# Date : Juin 2021
#============================================================
# Ce programme permet de retracer l'évolution phonétique de 
# mots latins vers le francais moderne. Il comporte trois modes:
#	- view: prend un mot latin en forme orthographique en argument 
#	et imprime les différentes étapes de son évolution ainsi que
# 	les meilleurs matchs trouvés dans Lexique3;
#	- evol: prend en arguments un mot latin et l'évolution trouvée par
# 	l'utilisateur (en forme orthographique) et retourne un message selon
#	que les réponses correspondent ou non. Propose ensuite de retracer 
#	l'évolution étape par étape et permet de modifier les résultats;
#	- test: prend en argument un fichier de type tsv comportant deux colonnes
# 	(mots latins et leur évolution), puis calcule la performance du programme 
# 	sur ce test set. 
#============================================================
# Usage :
# - perl LatinToFrench.pl view gaudi*am
# - perl LatinToFrench.pl evol gaudi*am joie
# - perl LatinToFrench.pl test test_set.txt
#============================================================

use strict;
use warnings; 
use String::Similarity;
use IO::Prompt::Simple;
use utf8;
use open ':std', ':encoding(utf-8)';

## Prétraitement : transforme le mot en forme phonétique et place l'accent tonique

sub word_to_phon {
	## Transforme la forme orthographique en forme phonétique
	my $w = $_[0];
	$w =~ s/[cq]/k/g;
	$w =~ s/nk/Gk/g;
	$w =~ s/ng/Gg/g;
	$w =~ s/gn/Gn/g;
	$w =~ s/l([^aeioul])/L$1/g;
	$w =~ s/x/ks/g;
	$w =~ s/[uv]([aeiou])/w$1/g;
	$w =~ s/^i([aeiou])/j$1/g;
	$w =~ s/([aeiou*])i(\*?[aeiou])/$1jj$2/g;
	return $w;
}

sub syllaber {
	## Découpe le mot en syllabes et en compte le nombre
	my $word = $_[0];
	my $res = "";
	my $l = 0;
	my $voy = "aeiouyOE@2951§3";	
	while ($word =~ /([^$voy]*((oe|ae|au)|[$voy]\*?)([^$voy]+$|(?=[ptdbkg][rl])|[^ptdbkg$voy](?=[rl])|[^$voy](?=[^'rl$voy]))?)/g) {
		$res =  $res.$1."-";
		$l ++;
	}
	chop($res); 
	return ($res, $l);
}

sub stress {
	## Place l'accent tonique au bon endroit dans le mot
	my $syll = $_[0];
	my $len = $_[1];
	my $w;
	# Si le mot ne contient qu'une seule syllabe : accent tombe dessus
	if ($len == 1) {
		$syll =~ s/([aeiou])/'$1/;
	}
	# Si le mot ne contient que 2 syllabes : accent sur la 1ère
	elsif ($len == 2) {
		$syll =~ s/^([^aeiou]*)([aeiou])/$1'$2/;
	}
	# Si la voyelle de l'avant-dernière syllabe est brève et libre : accent sur l'antépénultième
	elsif ($syll =~ /([aeiou]\*-[^-]+$)/) {
		$syll =~ s/([aeiou][^-]*-[^-]*[aeiou]\*-[^-]+$)/'$1/;
	}
	# Sinon : accent tombe sur la pénultième
	else {
		$syll =~ s/([aeiou][^-]*-[^-]+$)/'$1/;
	}
	$w = $syll;
	$w =~ s/-//g;
	return $w;
}
	
sub pretraitement {
	##Lance les trois fonctions de prétraitement et retourne le résultat
	my $word = $_[0];
	my $phon = word_to_phon($word);
	my @res = syllaber($phon);
	$phon = stress($res[0], $res[1]);
	return($res[0], $res[1], $phon);
}

## Changements phonétiques

sub premier_siecle {
	my $word = $_[0];
	my $lensyll = $_[1];
	my $voy = "aeiouE";   #Voyelles utilisées au 1er siècle
	
	## Syncope de certaines consonnes
	#m finaux (sauf monosyllabes)
	if (($lensyll != 1) and ($word =~ /m$/)) {
		chop($word);
	}
	#n devant s ou f
	$word =~ s/ns/s/g;
	$word =~ s/nf/f/g;
	#h (toutes positions)
	$word =~ s/h//g;

	## Fermeture des voyelles en hiatus
	#i et e brefs
	$word =~ s/([^'])[ie]\*('?[$voy])/$1j$2/g;
	#u et o brefs
	$word =~ s/([^'])[uo]\*('?[$voy])/$1w$2/g;
	#fusion des voyelles de même timbre
	$word =~ s/([$voy])('?\1)/$2/g;
	$word =~ s/(i)r('?\1)/r$2/g;
	
	##Amuïssements vocaliques
	#Pénultième atone : chute précoce 
	$word =~ s/('.+[bptdkg])[$voy]\*([lr].*[$voy].*$)/$1$2/;  #entre occlusive et liquide
	$word =~ s/('.+[lr])[$voy]\*([bptdkg].*[$voy].*$)/$1$2/;	
	$word =~ s/('.+[rln])[$voy]\*([dtr].*[$voy].*$)/$1$2/;	#entre consonnes homorganiques
	#Prétoniques internes(sauf a et entravées) : chute précoce 
	my @s = syllaber($word);
	$lensyll = $s[1];
	if ($lensyll >= 4) {
		#entre occlusive et liquide
		$word =~ s/([$voy].*[bptdkg])[eiou]\*?([lr]')/$1$2/;
		#entre consonnes homorganiques
		$word =~ s/([$voy].*[rl])[eiou]\*?(d')/$1$2/;
	}
	
	## Conséquences des chutes de voyelles
	#Vélarisation du l préconsonantique (sauf géminé)
	$word =~ s/([^l])l([^jl'$voy])/$1L$2/g;
	#Réduction des groupes consonantiques 
	$word =~ s/([^jw*'$voy])[^jrlw*'$voy]([^jwrl*'$voy])/$1$2/;
	$word =~ s/jj([^jw*'$voy])/j$1°j/;
	$word =~ s/ktj/ttj/g;
	$word =~ s/ktw/tt/g;
	$word =~ s/kst/st/g;
	$word =~ s/^eks/ess/g;
	
	##Monophtongaison des diphtongues
	$word =~ s/oe/e/;
	$word =~ s/ae/E/;

	##Prothèses vocaliques
	$word =~ s/^(sk|st|sp)/i*$1/;
	
	##Mouvements consonantiques
	#Spirantisation du b intervocalique 
	$word =~ s/([$voy]\*?)b('?[rj$voy])/$1B$2/g;
	#Perte de l'articulation vélaire du w initial, post-C disjoint ou intervocalique (devant V non postérieure)
	$word =~ s/^w/B/;		
	$word =~ s/([^tpmbtdkg$voy\*])w/$1B/g;
	$word =~ s/([$voy]\*?)w([aeiEj])/$1B$2/g;
	#Evolution du B intervocalique
	$word =~ s/([$voy]\*?)B('?[aeiEjr])/$1v$2/g;
	return $word;
}

sub latin_vulgaire {
	my $word = $_[0];
	my $voy = "aeiouEO";
	
	## Bouleversement vocalique
	$word =~ s/i\*/e/g;
	$word =~ s/'e\*/'E/;
	$word =~ s/([^$voy]*)'e([^$voy]+$)/$1'E$2/;  #Monosyllabe
	$word =~ s/e\*/e/g;
	$word =~ s/'o\*/'O/;
	$word =~ s/([^$voy]*)'o([^$voy]+$)/$1'O$2/;  #Monosyllabe
	$word =~ s/[ou]\*/o/g;
	
	## Renforcement articulatoire
	# Palatalisation des consonnes en position forte
	$word =~ s/(^k|(?<=[^G$voy])k)('?[eEi])/(ts°j)$2/g;
	$word =~ s/(^g|(?<=[^G$voy])g)('?[eEi])/(dZ°j)$2/g;
	$word =~ s/(^[tk]|(?<=[^$voy])[tk])j/(ts°j)j/g;
	$word =~ s/(^[dg]|(?<=[^$voy])[dg])j/(dZ°j)j/g;
	# Renforcement du yod en position forte
	$word =~ s/^j/(dZ°j)/g;
	$word =~ s/([bmv])j/$1(dZ°j)/g;
	$word =~ s/pj/p(tS°j)/g;
	# Palatalisation de consonnes en position faible
	$word =~ s/([$voy]\*?)tj/$1j(ts°j)j/g;	 #Entre voyelle et yod
	$word =~ s/([$voy]\*?)(ss?)j/$1j$2°jj/g;
	$word =~ s/([$voy]\*?)kj/$1t(ts°j)j/g;
	$word =~ s/([$voy]\*?)rj/$1jr°jj/g;
	$word =~ s/([$voy]\*?)lj/$1jJj/g;
	$word =~ s/([$voy]\*?)nj/$1jNj/g;
	$word =~ s/([$voy]\*?)k('?[eEi])/$1j(ts°j)$2/g;	  #Intervocalique
	$word =~ s/([$voy]\*?)Gk('?[eEi])/$1jN(ts°j)$2/g;
	$word =~ s/([$voy]\*?)Gg('?[eEi])/$1jNN$2/g;
	$word =~ s/([$voy]\*?)Gn/$1jNN/g;
	
	## Diphtongaisons spontanées romanes
	$word =~ s/'E([^$voy]([j$voy]|$))/'iE$1/;	#CV ou monosyllabe
	$word =~ s/'E([ptkgdb]r)/'iE$1/;	#Groupe OL
	$word =~ s/'E([aou]$)/'iE$1/;  #Ex: deu(voyelle libre)
	$word =~ s/'O([^$voy]([j$voy]|$))/'uO$1/;
	$word =~ s/'O([ptkgdb]r)/'uO$1/;
	
	## Affaiblissement de certaines consonnes
	$word =~ s/([$voy])[dg]j/$1jj/g;
	$word =~ s/([$voy])g(E|e|i)/$1jj$2/g;
	$word =~ s/([$voy])[kg]l/$1jJ/g;
	$word =~ s/([$voy])[kg]r/$1jr/g;
	$word =~ s/ks/js°j/g;
	$word =~ s/kt/jt°j/g;
	
	## Diphtongaisons conditionnées (voyelles entravées par yod)
	$word =~ s/'Ej/'iEj/;
	$word =~ s/'Oj/'uOj/;
	
	## Chute des dernières voyelles en position faible
	# Chute des pénultièmes atones
	$word =~ s/('[$voy]+[^$voy]+)[$voy](.*[$voy].*$)/$1$2/;
	# Chute des prétoniques internes (sauf a ou entravées)
	$word =~ s/(^[^'$voy]*[$voy][^'$voy]+)[eiouOE](?![^'*$voy]{2,})/$1/;
	$word =~ s/([a][^'$voy]+)[eiouOE]([^'$voy]')/$1$2/;	#Si 2 PTI dont /a/
	#Vélarisation du l préconsonantique (sauf quand l géminé)
	$word =~ s/([^l])l([^lj'$voy])/$1L$2/g;
	
	## Epenthèses consonantiques
	$word =~ s/m(r|l|L)/mb$1/g;
	$word =~ s/(n|z|l|L)r/$1dr/g;
	$word =~ s/sr/str/g;
	
	## Affaiblissement des consonnes intervocaliques
	#Sonorisation
	$word =~ s/([j$voy])t((°j)?['jrw$voy])/$1d$2/;   
	$word =~ s/([j$voy])s((°j)?['jrw$voy])/$1z$2/;
	$word =~ s/([j$voy])k((°j)?['jrw$voy])/$1g$2/;
	$word =~ s/([j$voy])\(ts°j\)(['jrw$voy])/$1\(dz°j\)$2/;
	#Spirantisation et assimilation selon l'environnement (postérieur/antérieur/mixte)
	$word =~ s/([ieEa])[gk]('?[ieEa])/$1jj$2/;
	$word =~ s/([uoO])[gk]('?[uoO])/$1$2/;
	$word =~ s/('[ieEa])[gk]([$voy])/$1jj$2/;
	$word =~ s/('[uoO])[gk]([$voy])/$1$2/;
	$word =~ s/([$voy])[gk]('[ieEa])/$1jj$2/;
	$word =~ s/([$voy])[gk]('[uoO])/$1$2/;
	#Consonnes bilabiales
	$word =~ s/([$voy])B('?[ieEarj])/$1v$2/g;
	$word =~ s/([$voy])B('?[uoOr])/$1$2/g;
	$word =~ s/w('?[uoO])/$1/g;
	$word =~ s/([ieEa])p('?[r$voy])/$1v$2/g;
	$word =~ s/([$voy])p('?[ieEar])/$1v$2/g;
	$word =~ s/([ieEaL])f('?[ieEa])/$1v$2/g;
	$word =~ s/(.+)f('?[uoO])/$1$2/g;
	
	## Mouvements consonantiques
	$word =~ s/^B/v/;
	$word =~ s/([^tp$voy])B/$1v/g;
	$word =~ s/B([^tp$voy])/v$1/g;
	$word =~ s/([tpmkgbd])w/$1/;
	return $word;
}

sub gallo_roman {
	my $word = $_[0];
	my $voy = "aeiouEO3";
	
	## Effets du renforcement articulatoire (I)
	#Palatalisation de k/g + a en position forte (initial ou appuyé)
	$word =~ s/kk(('?a)(?!E))/(tS°j)$1/g;
	$word =~ s/^k(('?a)(?!E))/(tS°j)$1/g;
	$word =~ s/([^$voy])k('?a)(?!E)/$1(tS°j)$2/g;
	$word =~ s/^g(('?a)(?!E))/(dZ°j)$1/g;
	$word =~ s/([^$voy])g('?a)(?!E)/$1(dZ°j)$2/g;

	## Monophtongaison de /au/
	$word =~ s/au/O/g;
	
	## Simplification de /ll/ final suivi de a
	$word =~ s/lla$/la/g;
	
	## Effets du renforcement articulatoire (II)
	#Diphtongaison conditionnée de /a/ tonique et libre 
	$word =~ s/(j|°j\))'a((?![^'$voy]{2,})|(?=[tdpbkg][r]))/$1'ie/g;
	#Fermeture du /a/ initial atone et libre
	$word =~ s/^([^$voy]*(j|°j\)))a((?![^'$voy]{2,})|(?=[tdpbkg][r]))/$1e/g;
	#Diphtongaisons spontanées françaises (voyelle tonique et libre)
	$word =~ s/'e((?![^'$voy]{2,})|(?=[tdpbkgv][r])|$)/'ei/;
	$word =~ s/'o((?![^'$voy]{2,})|(?=[tdpbkgv][r])|$)/'ou/;
	$word =~ s/'a((?![^'$voy]{2,})|(?=[tdpbkgv][r])|$)/'aE/;
	#Effet de Bartsch
	$word =~ s/(j|°j\))'ei((?![^'$voy]{2,})|(?=[tdpbkg][r]))/$1'i/g;
	
	##Mouvement vocalique (o ouvert atone)
	$word =~ s/(^|[^'])O/$1o/g;
	
	## Effet fermant des consonnes nasales
	$word =~ s/([^$voy])E(n|m)/$1e$2/g;
	$word =~ s/([^$voy])O(n|m)/$1o$2/g;
	$word =~ s/([^$voy])aE(n|m)/$1ai$2/g;
	
	## Tendances simplificatrices
	#Affaiblissement du d intervocalique
	$word =~ s/([$voy])d(['r$voy])/$1D$2/g;
	#Réduction des diphtongues
	$word =~ s/iE/ie/g;
	$word =~ s/uO/uo/g;
	$word =~ s/aE/E/g;
	#Simplification des occlusives géminées (pour ligne 321)
	$word =~ s/([tdpbkg])\1/$1/g;
	#Affaiblissement des voyelles finales
	my $lensyll = syllaber($word);
	if ($lensyll > 1) {
		$word =~ s/a([^$voy]*)$/3$1/;
		$word =~ s/[$voy]nt$/3nt/;
		$word =~ s/([tdpbkg][lr])[$voy](?=[^$voy]*)$/$1 3/;
		$word =~ s/([tdpbkg]{2})[$voy](?=[^$voy]*)$/$1 3/;
		$word =~ s/([vf]r)[$voy]([^$voy]*)$/$1 3/;
		$word =~ s/([^$voy]\(dZ°j\)j?)[$voy](?=[^$voy]*)$/$1 3/;
		$word =~ s/([^$voy]\(ts°j\)j?)[$voy](?=[^$voy]*)$/$1 3/;
		$word =~ s/(L[mn])[$voy](?=[^$voy]*)$/$1 3/;
		$word =~ s/(jr)[$voy](?=[^$voy]*)$/$1 3/;
		$word =~ s/(mn)[$voy](?=[^$voy]*)$/$1 3/;
		$word =~ s/([^$voy])[aeiouEO]([^j$voy]*)$/$1$2/;
		$word =~ s/ //g;
	}
	# Vélarisation du l géminé en position finale (cerveau, cheveu)
	$word =~ s/(e|E)ll$/$1L/g;
	#Simplification des consonnes géminées (sauf r)
	$word =~ s/([^rj$voy])\1/$1/g;
	$word =~ s/([^°]j)j/$1/g;
	#Dépalatalisation (sauf position finale)
	$word =~ s/jNj(.+)/N$1/g;
	$word =~ s/jN([^j]+)/N$1/g;
	$word =~ s/jJj(.+)/J$1/g;
	$word =~ s/jJ([^j]+)/J$1/g;
	$word =~ s/(°j\)?|N|J)j/$1/g;
	$word =~ s/([^°])j/$1i/g;
	$word =~ s/°j//g;
	#Formation de diphtongues de coalescence
	$word =~ s/Oi/oi/g;
	#Affaiblissement des consonnes finales (dévoisement)
	$word =~ s/b$/p/;
	$word =~ s/d$/t/;
	$word =~ s/g$/k/;
	$word =~ s/v$/f/;
	$word =~ s/dz$/ts/;
	$word =~ s/D$/T/;
	$word =~ s/m($|s$)/n$1/;  #dentalisation
	#Réduction de la triphtongue iei
	$word =~ s/iei/i/g;

	## Evolution des consonnes implosives
	$word =~ s/p(\(?[dtDT])/f$1/g;
	$word =~ s/bt/ft/g;
	$word =~ s/ts$/(ts)/g;
	$word =~ s/(N|J)s$/$1(ts)/g;
	$word =~ s/([^$voy])ns$/$1(ts)/g;
	#Chute de la consonne médiane (groupe de 3 C)
	$word =~ s/([^\)\('$voy])[^\)\('$voy]([^rl\)\('$voy])/$1$2/g;
	$word =~ s/([^\)\('$voy])\(.+\)([^r\)\('$voy])/$1$2/g;
	
	## Mouvement vocalique (prétoniques internes)
	$word =~ s/^([^'$voy]*[$voy][^'$voy]+)[aeiuo](([^'$voy]*['$voy]+)+)$/$1 3$2/;
	$word =~ s/ //;  #Artifice pour permettre utilisation du 3 dans la regex
	# Vélarisation du l préconsonantique 
	$word =~ s/l([^jl'$voy])/L$1/g;
	
	##Antériorisation du /u/
	$word =~ s/(^[^$voy]*|')u([^Oo])/$1y$2/g;
	$word =~ s/u(i|oi)/y$1/g;
	return $word;
}

sub archaique {
	my $word = $_[0];
	my $voy = "aeiouOE3y";
	
	## Tendances simplificatrices
	# Affaiblissement consonantique
	$word =~ s/[fv](\(?[tdTD])/$1/g;
	$word =~ s/([$voy])[tT]$/$1/g;
	$word =~ s/D//g;
	$word =~ s/[pbfvkg]([^$voy]+$)/$1/; 
	# Simplification des t et r géminés
	$word =~ s/t(\(t)/$1/g;
	$word =~ s/rr/r/g;
	
	## Mouvement au niveau des di/triphtongues (I)
	$word =~ s/uo(?=[mnN])/ye/g;	# Suivies par m, n ou N: nasalisation
	$word =~ s/uo/y2/g;
	$word =~ s/yoi/yi/g;
	$word =~ s/[eo]i(?![mnN])/ue/g;
	$word =~ s/ou(?![mnN])/2u/g;
	$word =~ s/ai(?![mnN])/Ei/g;
		
	## Vocalisation du L vélaire
	$word =~ s/OL/ou/g;
	$word =~ s/L/u/g;
	
	## Mouvement au niveau des di/triphtongues (II)
	$word =~ s/[iy]eu/i2u/g;
	$word =~ s/yoi/yi/g;
	$word =~ s/eu/2u/g;
	$word =~ s/[oO]u(?![mnN])/u/g;
	$word =~ s/iu/i/g;
	$word =~ s/yu/y/g;
	$word =~ s/Eu/Eau/g;
	
	## Mouvement vocalique
	#/a/ atone en hiatus
	$word =~ s/([^'])a([aoEO3y'])/$1 3$2/g;
	$word =~ s/ //g;
	#/a/ entravé par /s/ antéconsonantique
	$word =~ s/a(s[^'$voy])/a:$1/g;
	
	#/E/ tonique
	$word =~ s/'E(?!(i|au))/'e/g;
	#/e/ initial + s + C
	$word =~ s/(^[^$voy]*)es([^'$voy])/$1e:$2/;
	#/e/ initial entravé
	$word =~ s/(^[^$voy]*)e([^':mnN\($voy][^'$voy])/$1E$2/;
	#/e/ tonique entravé
	$word =~ s/'e([^':mnN\($voy][^'$voy])/'E$1/;
	#/e/ initial libre ou en hiatus
	$word =~ s/(^[^'$voy]*)e([^:$voy]['$voy])/$1 3$2/;
	$word =~ s/(^[^'$voy]*)e([aeoOE3y'])/$1 3$2/;
	$word =~ s/(^[^']$voy*)e(\()/$1 3$2/;
	$word =~ s/ //;
	
	#/o/ initial
	$word =~ s/(^[^$voy]*)o(?![iumnN])/$1u/g;
	#/o/ tonique entravé
	$word =~ s/'o([^':mnN$voy][^'$voy])/'u$1/g;
	#/o/ atone en hiatus
	$word =~ s/([^'])o([aeoEO3y'])/$1u$2/g;
	#/O/ tonique entravé par s
	$word =~ s/'O(s[^'$voy])/o:$1/g;
	#/O/ tonique suivi par /z/ ou /v/
	$word =~ s/'O(z|v)/'o:$1/;
	#/O/ tonique en finale absolue ou devant /3/
	$word =~ s/'O($|3)/'u$1/;

	## Chute de s et z antéconsonantiques
	$word =~ s/[sz]([^'\)\($voy])/$1/g;
	
	return $word; 
}

sub ancien_francais {
	my $word = $_[0];
	my $voy = "aeiouEO3y\@512§";
			
	##Nasalisation
	#Nasalisation des diphtongues
	$word =~ s/[ae]i[mnN]($|[^'$voy])/5$1/g;
	$word =~ s/[ae]i([mnN])/E$1/g;
	$word =~ s/ou[mnN]($|[^'$voy])/§$1/g;
	$word =~ s/ou([mnN])/O$1/g;
	$word =~ s/oi[mnN]($|[^'$voy])/w5$1/g;
	$word =~ s/oi([mnN])/wa$1/g;
	$word =~ s/ie[mnN]($|[^'$voy])/j5$1/g;
	$word =~ s/ie([mnN])/jE$1/g;
	$word =~ s/ye([mnN])/85$1/g;
	#Nasalisation des voyelles
	$word =~ s/a[nmN]($|[^'$voy])/\@$1/g;
	$word =~ s/e[mnN]($|[^'$voy])/\@$1/g;
	$word =~ s/e([mnN])/E$1/g;
	$word =~ s/o[mnN]($|[^'$voy])/§$1/g;
	$word =~ s/o([mnN])/O$1/g;
	$word =~ s/i([mnN]($|[^'$voy]))/5$1/g;
	$word =~ s/y([mnN]($|[^'$voy]))/1$1/g;
	
	## Tendances simplificatrices 
	#Réduction des di/triphtongues (bascule de l'accent)
	$word =~ s/('?)ie/j$1e/g;
	$word =~ s/y2/2/g;
	$word =~ s/yi/8i/g;
	$word =~ s/('?)ue/w$1e/g;
	$word =~ s/i2u/j2/g;
	$word =~ s/Eau/au/g;
	$word =~ s/2u/2/g;
	$word =~ s/Ei/E/g;
	#Réductions consonantiques
	$word =~ s/\(ts\)/s/g;
	$word =~ s/\(tS\)/S/g;
	$word =~ s/\(dz\)/z/g;
	$word =~ s/\(dZ\)/Z/g;
	$word =~ s/\(k°w\)/k/g;
	$word =~ s/\(g°w\)/g/g;
	#Effacement de yod
	$word =~ s/j([SZNJ])/$1/g;
	$word =~ s/([SZNJ]'?)j/$1/g;
	$word =~ s/([^'$voy])j('?)er$/$1$2er/;
	#Affaiblissement consonantique
	$word =~ s/Os$/o:/;
	$word =~ s/as$/a:/;
	$word =~ s/nt$//;   #désinence
	$word =~ s/[^lr:$voy]$//; # amuïssement des consonnes finales 
	$word =~ s/([$voy].*[^w]'|[$voy]')er$/$1e/; #r final (>1 syll, pas uer ou wer)
	#Affaiblissement de /J/
	$word =~ s/J/j/g;
	
	## Recul de /r/
	$word =~ s/r/R/g;
	
	## Modification de /we/
	$word =~ s/([pbtdkg][l])w('?)e/$1$2E/g;
	$word =~ s/w('?)e/w$1a/g;
	
	return $word;
}

sub moyen_francais {
	my $word = $_[0];
	my $voy = "aeiouEO3y\@512§9";
	
	## Tendances simplificatrices
	#Réduction de /au/
	$word =~ s/au/o/g;
	#Réduction des hiatus
	$word =~ s/[3]('?[$voy])/$1/g;
	$word =~ s/([$voy])('?\1)/$2/g;
	#Amuïssement du /3/ final
	$word =~ s/3$//;
	
	return $word;
}

sub francais_moderne {
	my $word = $_[0];
	my $voy = "aeiouEO3y@512§9";
	
	## Loi de position
	$word =~ s/'e([^$voy]($|[^$voy]))/'E$1/g;
	$word =~ s/'2([^$voy]($|[^$voy]))/'9$1/g;
	
	## Modification vocalique (plus de voyelles longues)
	$word =~ s/://g;
	
	## Passage de y + v à 8
	$word =~ s/y('?[$voy])/8$1/g;
	
	return $word;
}

## Reconnaissance du mot trouvé

sub create_hash {
	## Crée deux tables de hachage à partir de la version simplifiée de Lexique3
	open (my $phon_dic, "<", "simple_lex.tsv");
	my %dict;  #key : forme phonétique, values: orthographiques
	my %dict2; #key : forme orthographique, values: phonétique

	while(my $ligne = <$phon_dic>){
		chomp($ligne);
		my @info = split(/\t/, $ligne);
		if (exists($dict{$info[1]})) {
			if (index($dict{$info[1]}, ",$info[0]") == -1) {
				$dict{$info[1]} = $dict{$info[1]}.",$info[0]";
			}
		}
		else {
			$dict{$info[1]} = $info[0];
		}
		if (not exists($dict2{$info[0]})) {
			$dict2{$info[0]} = $info[1];
		}
	}
	close $phon_dic;
	my @res = (\%dict, \%dict2);	  #Références aux tables de hachage
	return (@res);
}

sub find_word {
	## Trouve une forme phonétique dans la table de hachage et en retourne les meilleurs
	## matchs orthographiques
	my $phon = $_[0];
	my %dict = %::dict;		#Variable globale
	my $prox = 0;
	my $res = "";

	foreach my $key (keys %dict)  {
		my $sim = similarity $phon, $key;
		if ($sim > $prox) {
			$res = "$dict{$key}";
			$prox = $sim;
		}
		elsif ($sim == $prox) {
			$res = $res.",$dict{$key}";
		}
	}
	return $res;
}


## Evolution du mot

sub verbose_evol {
	## Réalise l'évolution du mot passé en argument et en imprime les étapes
	
	#Prétraitement
	my $lat = $_[0];
	my @pre = pretraitement($lat);
	print(
	"\n### \tPrétraitement\t\t ### 
Découpe en syllabes : $pre[0]  ($pre[1] syllabe(s))
Place de l'accent tonique : $pre[2] \n");

	#Evolution
	my $word = $pre[2];
	my $lensyll = $pre[1];
	$word = premier_siecle($word, $lensyll);
	print("\n### \t Latin vulgaire \t ### \nEvolution au 1er siècle : $word \n");
	$word = latin_vulgaire($word);
	print("Evolution au 5ème siècle : $word \n");
	$word = gallo_roman($word);
	print("\n### \t Gallo-roman \t\t ### \nEvolution au 8ème siècle : $word \n");
	$word = archaique($word);
	print("\n### \t Français archaïque \t ###\nEvolution au 12ème siècle : $word \n");
	$word = ancien_francais($word);
	print("\n### \t Ancien français \t ###\nEvolution au 13ème siècle : $word \n");
	$word = moyen_francais($word);
	print("\n### \t Moyen français \t ###\nEvolution au 16ème siècle : $word \n");
	$word = francais_moderne($word);
	print("\n### \t Français moderne \t ###\nEvolution au 18ème siècle : $word \n");
	#Enlever l'accent tonique
	$word =~ s/'//;	
	
	#Meilleurs matchs
	print("\n### \t Meilleurs matchs \t ###\n");
	print(find_word($word)."\n");
	return $word; 
}

sub silent_evol {
	## Réalise l'évolution du mot passé en argument et retourne la forme phonétique
	## finale ainsi que ses meilleurs matchs
	
	#Prétraitement
	my $lat = $_[0];
	my @pre = pretraitement($lat);
	#Evolution
	my $word = $pre[2];
	my $lensyll = $pre[1];
	$word = premier_siecle($word, $lensyll);
	$word = latin_vulgaire($word);
	$word = gallo_roman($word);
	$word = archaique($word);
	$word = ancien_francais($word);
	$word = moyen_francais($word);
	$word = francais_moderne($word);
	#Enlever l'accent tonique
	$word =~ s/'//;	
	#Meilleurs matchs
	my $res = find_word($word);
	return ($word, $res); 
}

sub performance_test {
	## Evalue la performance du programme sur un fichier de test passé en argument
	my $correct = 0;
	my $total = 0;
	my $test = $_[0];
	open(my $list, "<", $test);
	print("Test de performance en cours... \n");
	while (my $ligne = <$list>) {
		$total ++;
		chomp($ligne);
		my @info = split(/\t/, $ligne);
		my @res = silent_evol($info[0]);
		if (index($res[1], $info[1]) != -1) {
			$correct ++;
		} 		
	}
	print("\nPerformance: ".$correct/$total*100 ." % \n");
}
	
sub step_by_step {
	## Imprime l'évolution du mot latin passé en argument pas à pas et permet à l'utilisateur
	## d'intervenir à chaque étape
	
	#Prétraitement
	my $lat = $_[0];
	my @pre = pretraitement($lat);
	print("\n### \tPrétraitement\t\t ### 
Découpe en syllabes : $pre[0]  ($pre[1] syllabe(s))
Place de l'accent tonique : $pre[2] \n");
	
	#Evolution
	my $word = $pre[2];
	my $lensyll = $pre[1];
	$word = modify($word);
	$word = premier_siecle($word, $lensyll);
	print("\n### \t Latin vulgaire \t ### \nEvolution au 1er siècle : $word \n");
	$word = modify($word);
	$word = latin_vulgaire($word);
	print("Evolution au 5ème siècle : $word \n");
	$word = modify($word);
	$word = gallo_roman($word);
	print("\n### \t Gallo-roman \t\t ### \nEvolution au 8ème siècle : $word \n");
	$word = modify($word);
	$word = archaique($word);
	print("\n### \t Français archaïque \t ###\nEvolution au 12ème siècle : $word \n");
	$word = modify($word);
	$word = ancien_francais($word);
	print("\n### \t Ancien français \t ###\nEvolution au 13ème siècle : $word \n");
	$word = modify($word);
	$word = moyen_francais($word);
	print("\n### \t Moyen français \t ###\nEvolution au 16ème siècle : $word \n");
	$word = modify($word);
	$word = francais_moderne($word);
	print("\n### \t Français moderne \t ###\nEvolution au 18ème siècle : $word \n");
	$word = modify($word);

	#Enlever l'accent tonique
	$word =~ s/'//;	
	#Meilleurs matchs
	print("\n### \t Meilleurs matchs \t ###\n");
	print(find_word($word)."\n");
}

sub modify {
	## Propose à l'utilisateur de modifier le mot passé en argument et retourne le nouveau
	## mot le cas échéant
	
	my $word = $_[0];
	my $str = "Modifier ?\n";
	my $check = prompt $str, { anyone => { n => 0, o => 1 } };
	if ($check == 1) {
		my $new = prompt "Nouveau";
		my $sure = prompt 'Valider ?', { anyone => [qw/o n/] };
		if ($sure eq "n") {
			$new = prompt "Nouveau";
		}
		$word = $new;
	}
	return $word;
}

## Préparation des dictionnaires (globaux)

my @h = create_hash();
our %dict = %{$h[0]};
our %dict2 = %{$h[1]};

## Exécution du programme selon le mode

my $mode = $ARGV[0];
chomp($mode);

if ($mode eq "view") {
	my $word = $ARGV[1];
	chomp($word);
	verbose_evol($word);
}

elsif ($mode eq "test") {
	my $set = $ARGV[1];
	chomp($set);
	performance_test($set);
}

elsif ($mode eq "evol"){
	my $word = $ARGV[1];
	my $answer = $ARGV[2];
	chomp($word);chomp($answer);
	my @res = silent_evol($word);
	my %dict2 = %::dict2;
	
	if ($res[1] =~ /(^|,)$answer(,|$)/) {
		print("Félicitations ! Votre réponse est correcte\n");
	}
	else {
		my $sim = similarity $res[0], $dict2{$answer};
		if ($sim > 0.7) {
			print("Etes-vous certain.e que la réponse n'est pas plutôt : $res[1] ?\n");
		}
		else {
			print("Cette réponse semble incorrecte\n");
		}
	}
	my $str = "\nSouhaitez-vous voir l'évolution du mot ?\n";
	my $ans = prompt $str, { anyone => { n => 0, o => 1 } };
	if ($ans == 1) {
		step_by_step($word);
	}
}

else {
	print("Veuillez entrer un mode valide (view, test ou evol) \n");
}