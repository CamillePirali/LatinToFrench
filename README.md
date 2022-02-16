# LatinToFrench

This Perl programme takes a Latin word as input and retraces its phonetic evolution through history up to modern-day French. It was conceived as a tool for students and linguists to practice or test their knowledge of diachronic phonetic changes, or simply compare their analysis to the one produced by the programme.

## Preparation

Before launching the programme, users must complete the following steps:

- Make sure that Perl is installed on their computer;
- Download, at a minimum, the files **LatinToFrench.pl** and **simple_lex.tsv**;
- Save those files in the same folder;
- Install the Perl modules `String::Similarity` and `IO::Prompt::Simple`, using the following commands in their terminal:

  ```
  cpanm String::Similarity
  ```
  ```
  cpanm IO::Prompt::Simple
  ```

## Running the programme

In your terminal, navigate to the folder containing the files mentioned above. If you are a Windows user, you might need to enter the following command to display UTF-8 characters properly:
  ```
  chcp 65001
  ```
Three different modes can be used, each with a different syntax and result. They are:

1. **View**

Syntax: *perl LatinToFrench.pl view gaudi\*am*

Retraces the steps of the given Latin word's evolution, and prints the best matches found in contemporary French (based on a simplified version of Lexique3).

Example of output:

    ### Prétraitement ###
    Découpe en syllabes : gau-di*-am (3 syllabe(s))
    Place de l'accent tonique : g'audi*am

    ### Latin vulgaire ###
    Evolution au 1er siècle : g'audja
    Evolution au 5ème siècle : g'aujja

    ### Gallo-roman ###
    Evolution au 8ème siècle : (dZ)'oi3

    ### Français archaïque ###
    Evolution au 12ème siècle : (dZ)'ue3

    ### Ancien français ###
    Evolution au 13ème siècle : Zw'a3

    ### Moyen français ###
    Evolution au 16ème siècle : Zw'a

    ### Français moderne ###
    Evolution au 18ème siècle : Zw'a

    ### Meilleurs matchs ###
    joie,joies

2. **Evol**

Syntax: *perl LatinToFrench.pl evol gaudi\*am joie*

Compares the result provided by the user (in its modern French orthographic form) and the one obtained by the script. A different message is printed according to how similar the two results are. The programme then offers to see the evolution step by step, and allows users to edit each output if necessary, in order to explore different possible evolutions. 

Example of output:

    Félicitations ! Votre réponse est correcte

    Souhaitez-vous voir l'évolution du mot ?
    (n/o) : n

3. **Test**

Syntax: *perl LatinToFrench.pl test test_set.txt*

Evalutes the performance of the programme on a test set. The file must have the following structure: two tab-separated columns, the first one containing Latin words whose evolution to retrace, the second their correct evolution in modern-day French. 

Example of output:

    Test de performance en cours...

    Performance: 89.6551724137931 %

## Important notes

- The words given as arguments must be in lowercase and in their orthographic form : the programme will take care of converting them to their phonetic form.
- Short vowels in the Latin words must be followed by "\*" to guarantee the efficiency of the programme. If you're unsure about whether a vowel is long or short, you can look online or try both options to see which one seems to work best. (Tip: As a rule, vowels in a hiatus tend to be short).
- The word's evolution is retraced phonetically. The following table describes the symbols used to represent relevant phonemes of the International Phonetic Alphabet:

<div align="center">
  <img width="450" alt="phoneme_table" src="https://user-images.githubusercontent.com/62525365/154285529-b14c82b7-0de8-45f9-bab6-1b0ae73dcb1e.PNG">
</div>

## Illustrations

Below are examples of words which can be used to test the programme.

| Original word  | French evolution | Best matches returned  |
| -------------- | ---------------- | ---------------------- |
| Vine\*am       | Vigne */vinj/*   | **vigne**, vignes         |
| Cohortem       | Cour */kur/*     | **cour**, coure, courent, coures, courre, cours, court, courts |
| Maledice\*re   | Maudire */modir/*| **maudire** ,maudirent |
| Caelum         | Ciel */sjel/*    | **ciel**, ciels            |
| Cooperire      | Couvrir */kuvʁiʁ/* | **couvrir**, couvrirent | 
| Cantare        | Chanter */ʃɑ̃te/* | **chanter**, chantez, chanté, chantée, chantées, chantés |
| Pale\*a        | Paille */paj/*   | **paille**, paille, pailles |
| Sabi\*um       | Sage */saʒ/*     | **sage**, sage, sages |
| O\*pe\*ra      | Œuvre */œvʁ/*    | **oeuvre**, oeuvre, oeuvrent, oeuvres |
| Caballicare    | Chevaucher */ʃəvoʃe/* | **chevaucher**, chevauchez, chevauché, chevauchée, chevauchées, chevauchés |
| Capi\*llos     | Cheveux */ʃəvø/* | cheveu, **cheveux** |
| Canicu\*la     | Chenille */ʃənij/* | **chenille**, chenilles |
| Maturum        | Mûr */myʁ/*      | mur, mure, murent, mures, murs, **mûr**, mûre, mûres, mûrs |
| Nepotem        | Neveu */nəvø/*   | **neveu**, neveux
