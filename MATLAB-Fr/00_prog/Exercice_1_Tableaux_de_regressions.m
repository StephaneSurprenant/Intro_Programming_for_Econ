%
% Auteur: Stephane Surprenant, UQAM
% Creation: 03/08/2019
%
% Description: Ce script vous invite a construire des tableaux de resultats
% typiques en economie (surtout en microeconometrie). Je vous donne un
% exemple de comment le faire. Ensuite, je vous demande de le faire pour un
% autre cas avec les memes donnees.
%
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
addpath(paths.too);

% ======================================================================= %
%% 1. Importation des donnees
% ======================================================================= %

% Donnees:
d.data  = readtable([paths.dat, 'Labor_market_sim.csv']);
d.data  = table2array(d.data);
d.names = {'Age', 'Experience', 'Salaire', 'Sexe', ...
           'Diplome post-secondaire', 'Quebec'};
       
% ======================================================================= %
%% 2. Faire les regressions
% ======================================================================= %

% On va faire 4 regressions pour explorer l'effet du diplome sur les
% salaires dans nos donnees simulees. Voici les 4 regressions:
% salaire(i) = b0 + b1*dip + e(i)
% salaire(i) = b0 + b1*dip + b2*sexe + b3*dip*sexe + e(i)
% salaire(i) = b0 + b1*dip + b2*sexe + b3*dip*sexe + b4*age + e(i)
% salaire(i) = b0 + b1*dip + b2*sexe + b3*dip*sexe +
%              b4*age^2 + b5*Qc + e(i)

% On veut mettre les resultats dans un tableau. L'idee est d'avoir une
% regression par colonne. Les lignes vont correspondres aux b0 à b5, en
% plus de leurs ecarts-types. Ensuite, on veut avoir le nombre
% d'observations et le R2 ajuste.

% On cree une matrice pour contenir les resultats
regression_table       = nan(6*2+2,4);
N                      = size(d.data,1); 
regression_table(13,:) = N;
% Comme il n'y a pas d'observations manquantes, toutes les regressions
% seront faites avec toutes les donnes.

% On va ensuite creer une cellule qui avoir autant d'entrees qu'on a de
% regressions. Dans chaque entree, on va mettre la matrice des regresseurs
% avec une colonne de 1 en premier pour la constante. L'idee est qu'on va
% remplir le tableau avec des boucles.
regressors = cell(4,1);
regressors{1} = [ones(N,1), d.data(:,5)];
regressors{2} = [ones(N,1), d.data(:,[5,4]), d.data(:,5).*d.data(:,4)];
regressors{3} = [ones(N,1), d.data(:,[5,4]), d.data(:,5).*d.data(:,4), ...
                 d.data(:,1)];
regressors{4} = [ones(N,1), d.data(:,[5,4]), d.data(:,5).*d.data(:,4), ...
                 d.data(:,1).^2, d.data(:,6)];
             
% Si vous utilisez ma fonction make_latex(), il y a une option pour mettre
% des etoiles pour la significativite. L'idee est de donner une liste de
% symbole et une matrice avec des 0 ou on ne veut rien et une chiffre
% indiquant la position du symbole desire dans notre vecteur de symboles ou
% on veut quelque chose.
annotate = zeros(size(regression_table));
sym      = {'*','**','***'};
             
% On va maintenant effectuer les regressions. Il y a plusieurs fonctions
% pour le faire, y compris ecrire tout soi-meme. Pour le besoin de la
% cause, je vous ai fait une fonction qui fait tout pour vous sous
% hypothese d'homoscedasticite. Le 3e 1 indique d'afficher les resultats.
% Vous pouvez le mettre a 0 si vous voulez.
y = d.data(:,3);
for jj = 1:4
   X       = regressors{jj}; % Selection des regresseurs
   results = reg(X,y,0,0,1); % Regression
   
   % Ajout des coefficients et des ecarts-types
   Ngr     = size(results.table,1);
   % Les coefficients sont a toutes les 2 entrees, a chaque fois suivis des
   % ecarts-types. Attention de toujours remplir vos tableaux en ordre!
   regression_table(1:2:2*Ngr,jj) = results.table(:,1);
   regression_table(2:2:2*Ngr,jj) = results.table(:,2);
   % On ajoute le R2 ajuste
   regression_table(end,jj)       = results.reg_stat(2);
  
   % Significativite des coefficients
   p                      = results.table(:,4);
   annotate(1:2:2*Ngr,jj) = (p <= 0.10) + (p <=0.05) + (p <= 0.01);
   % NB: MATLAB considere que 1=vrai et 0=faux, d'ou l'idee ci-haut.
end

% ======================================================================= %
%% 3. Faire le tableau
% ======================================================================= %

% Maintenant, on va faire le tableau et l'exporter en format .tex.

% CONSEIL IMPORTANT :
% Je vous conseille tres fortement d'apprendre à vous servir de LATEX. Un
% gros probleme des travaux longs (memoires, articles et theses) est qu'on 
% fait des ajustements frequents. LATEX permet d'automatiser au maximum la 
% mise en page: vous payez le prix une seule fois. La suite Office peut 
% faire le travail, mais ca vous force a faire beaucoup de mise en page
% vous-meme -- c'est une perte de temps epouvantable. Ca prend environ 3 a
% 4 heures maximum apprendre la base de LATEX: faites-le des que possible.

% On transforme la matrice en cellule:
tab = num2cell(regression_table);
% Par caprice, les gensm ettent souvent les ecarts-types entre parentheses.
% On peut le faire en transformant les bonnes lignes en chaine de
% caracteres et en ajoutant les symbols desires:
for ii = 2:2:12
    for jj = 1:4
       if ~isnan(tab{ii,jj})
          tab{ii,jj} = ['(', num2str(tab{ii,jj}), ')'];
       end
    end
end

% On a besoin de noms de colonnes et de lignes dans notre tableau.
rownames = cell(1,size(regression_table,1));
rownames{1} = 'Intercept';
rownames{2} = ' ';
nlist       = {'Diplôme', 'Sexe','Dip.x Sexe', 'age(3)/age$^2$ (4)', ...
               'Qc'};

count = 1;
for ii = 3:2:12
   rownames{ii}   = nlist{count};
   rownames{ii+1} = ' ';
   count          = count + 1;
end
rownames{13} = 'Nobs.';
rownames{14} = 'R2 ajusté';

colnames = {'MCO (1)', 'MCO (2)', 'MCO (3)', 'MCO (4)'};
% Un titre, evidemment:
title    = 'Effet du diplome sur le salaire';
% Un chemin et un nom pour le fichier .tex qu'on va creer
fname    = [paths.out, 'Exemple_regressions'];
% Des notes sous le tableau:
notes    = ['La variable dépendante est le salaire.', ...
            ' La regression (3) inclus l''âge, alors que (4)', ...
            ' inclut l''âge au carré. Le diplôme est un diplôme', ...
            ' post-secondaire. Les femmes correspondent au cas', ...
            ' sexe = 0 et les ontariens au cas Qc = 0.'];

% On construit et on sauvegarde le tableau. Attention: on veut des virgules
% pour les decimales quond on redige en francais!
table = make_latex(tab, ...
           'row', rownames, 'col', colnames, ...
           'annotate', annotate, 'sym', sym, ...
           'title', title, 'dec', 3, ...
           'french_dec', true, 'f_name', fname, ...
           'notes', notes, 'save', true);
       
disp(table.table); % Montre le code latex genere ci-haut
       
% Pour vous donnez une idee, le tableau a l'air de ceci:
table2 = cell2table(tab, ... 
                    'VariableNames', {'OLS_1', 'OLS_2', ...
                                      'OLS_3', 'OLS_4'}, ...
                    'RowNames', {'Intercept', 'sd(I)', ...
                                 'Diplome', 'sd(D)', ...,
                                 'Sexe', 'sd(S)', ...
                                 'DipxSexe', 'sd(SxD)', ...
                                 'Age/age2', 'sd(A/A2)', ...
                                 'Qc', 'sd(Qc)', ...
                                 'Nobs', 'R2a'});
disp(table2);   
% ======================================================================= %
%% 4. EXERCICE 1.1: faire un nouveau tableau
% ======================================================================= %

% Vous devez par vous-meme effectuer 3 regressions et construire un tableau
% similaire au tableau ci-haut. Je vous donne les equations de regressions,
% mais je ne vous dis pas comment faire. Par contre, tout doit y etre.

% Indice sur le format du tableau: le tableau ci-haut aurait aussi pu etre
% fait avec 2 lignes de plus. C'est-a-dire qu'on aurait pu mettre age et
% age^2 separemment. C'est d'ailleurs la facon normale de proceder.

% Regressions:
% salaire(i) = b0 + b1*sexe + e(i)
% salaire(i) = b0 + b1*sexe + b2*sexe*diplome + e(i)
% salaire(i) = b0 + b1*sexe + b2*sexe*age + b3*diplome + e(i)

% Amusez-vous!

% ======================================================================= %
%% 5. EXERCICE 1.2: faire des figures
% ======================================================================= %

% Dans le script 'Introduction', il y a des exemples de figures. Pour cet
% exercice, vous allez effectuer une regression de votre choix et recuperer
% les valeurs predites (yhat = X*bhat). On veut comparer les valeurs
% predites aux valeurs realisees dans un espace particulier.

% Exemple:
% Je le fais avec la derniere valeure assignee a X et a y
P       = X*((X'*X)\X'); % Matrice de projection orthogonale
predict = P*y;
% On va faire des histogrammes pour voir la distribution des salaires chez
% les diplomes post-secondaires. Sur la meme figures, on compare les
% realisations aux valeurs predites.

histogram(y(X(:,2)==1)); 
hold on;
histogram(predict(X(:,2)==1));
legend('Realisation', 'Prevision','Location', 'northwest');
hold off;
print([paths.out, 'Exemple_de_figure'], '-dpng');
close;

% A votre tour:
% Vous devez sortir un nuage de points, cette fois. Ceci suppose que vous
% trouviez par vous-meme comment utiliser la fonction 'scatter' de MATLAB.
% Prenez une regression qui contient l'age. Sur l'axe des X, on a l'age et,
% sur l'axe des Y, on a le salaire. Le principe est le meme que ci-haut: on
% trace un premier nuage pour les salaires realises. On utilise 'hold on'
% pour ajouter un second nuage dans la meme figure et on reapplique la
% fonction scatter. On peut mettre une legende et on sauvegarde dans
% '30_output' sous un nouveau nom.

% Indice: help scatter
