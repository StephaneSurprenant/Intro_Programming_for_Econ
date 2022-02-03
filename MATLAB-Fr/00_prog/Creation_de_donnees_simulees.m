%
% Auteur: Stephane Surprenant, UQAM
% Creation: 03/08/2019
%
% Description: Ce script cree des donnees simulees pour certains des
% exercices.
% ======================================================================= %
%% 0. Initialisation
% ======================================================================= %

% On efface tout pour commencer
clear; clc; close all;

% On choisit le dossier de travail comme repertoire courant
wd = ['/home/stephane/Dropbox/', ...
    'Introduction_aux_logiciels_de_calculs/MATLAB'];
cd(wd);

% On cree nos chaines de caracteres pour les chemins relatifs
paths.dat = '10_data/';
paths.too = '20_tools/';
paths.out = '30_output/';

% On ajoute le chemin vers nos fonctions personalisees
addpath(paths.too);%% 0. Initialisation

% ======================================================================= %
%% 1. Marche du travail
% ======================================================================= %

% Je vous cree une fausse coupe transversale de travailleurs canadiens. Une
% partie travail au Quebec et, l'autre, en Ontario. Je fais expres de creer
% un modele lineaire dans les parametres, mais non-linaire dans les
% variables.

% Nombre de personnes
N = 1000;
% Nom des variables
names = {'Age', 'Experience', 'Salaire', 'Sexe', ...
         'Diplome post-secondaire', 'Quebec'};
K     = size(names,2);

% On initialise la matrice qui va contenir nos donnees simulees
X      = nan(N,K);
% On utilise une graine (seed) pour le generateur de nombre aleatoire
% (random number generator) afin de pouvoir toujours recuperer les memes
% valeurs:
rng(1234);
% Age (annese): partie entiere d'une normale N(25,3^2)
X(:,1) = round(25 + 3*randn(N,1));
% On va faire veillir les gens de 17 ans et moins de 15 ans
X((X(:,1) <= 17),1) = X((X(:,1) <= 17),1) + 15;

% Experience (annees): On va faire quelquechose de similaire, mais par
% tranche d'age.
gr = [(X(:,1) <= 20)              , (X(:,1) > 20 & X(:,1) <= 25), ...
      (X(:,1) > 25 & X(:,1) <= 30), (X(:,1) > 30)];
m  = [2,4,8,12];
for jj = 1:4
  Ngr           = sum(gr(:,jj));
  X(gr(:,jj),2) = round(m(jj) + randn(Ngr,1));
end

% Salaire (on le garde pour la fin: c'est la variable dependente)
% Sexe (0: femme)
X(:,4) = round(rand(N,1));

% Diplome post-secondaire:
% Dans notre monde siumle, les femmes ontariennes etudient beaucoup, les
% homme quebecois etudient peu et les deux autres groupes sont similaires.

% Quebec (1: Quebec, 0: Ontario):
X(:,6) = round(rand(N,1));

% Diplome:
X(:,5) = 0; % On remplit de zeros et on revise par la suite
f_ont  = (X(:,4) == 0)&(X(:,6) == 0);
h_qc   = (X(:,4) == 1)&(X(:,6) == 1);
% Femme ontarienne:
Ngr        = sum(f_ont);
X(f_ont,5) = round(rand(Ngr,1)+0.1);
% Homme quebecois:
Ngr        = sum(h_qc);
X(h_qc,5)  = round(rand(Ngr,1)-0.1);
% Autres:
Ngr        = sum((h_qc + f_ont) == 0);
X((h_qc+f_ont)==0,5)  = round(rand(Ngr,1));
% Et les gens de moins de 20 ans et moins n'ont pas de diplome
% post-secondaire:
X(gr(:,1),5) = 0;

% Finalement! Le salaire (miliers de CAD):
beta = [25000 500 -500 20 12 2000]';
% Ordre: Age, Exp, Sal, Sexe, Dip, Qc
X(:,3) = beta(1) + beta(2)*X(:,4) + beta(3)*X(:,6) + ...
         beta(4)*X(:,1).*X(:,2) + beta(5)*X(:,1).^2 + ...
         beta(6)*X(:,5).*X(:,4) + 8000*randn(N,1);

% On transfere le tout vers un fichier .csv:
data = X;
% Il faut creer une entete pour les titres de colonnes
header = [names; repmat({','}, 1, numel(names))];     % Ajout des virgules
header = header(:)';                               
header = cell2mat(header);              % Conversion en chaine de cracteres

% Etablir une connexion a un fichier .csv et inscrire l'entete.
fname  = [paths.dat, 'Labor_market_sim.csv'];
fid    = fopen(fname, 'w');   % Ouvrir avec l'option d'ecriture
fprintf(fid, '%s\n', header); % Ecrire
fclose(fid);                  % Fermer

% On sauvegrade notre matrice a la suite des titres
dlmwrite(fname, data, '-append');