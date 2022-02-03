%
% Auteur: Stephane Surprenant, UQAM
% Creation: 02/08/2019
%
% NB: Je deconseille l'utilisation d'accent dans les commentaires.
%
% Description:
% Ceci est un script MATLAB. Le but est de vous introduire a l'utilisation 
% de ce logiciel. Une partie du travail consiste a vous donnez un exemple 
% de bonnes habitudes de travail, comme ajouter des commentaires comme
% ceux-ci, utiliser une en-tete et utiliser des chemins relatifs.
%
% Ce fichier couvre vraiment la base. Le but est de vous donnez une idee du
% fonctionnement et de comment fouiller quand vous ne savez pas comment
% faire quelquechose. J'utilises un exercice tout bete de macroeconomie que
% vous allez certainement revoir cet hivers (pour les gens a la maitrise).
%
% Modifications:
% 1. Entrez d'eventuelles mises a jour
% ======================================================================= %
% INPUTS                          DESCRIPTION
% Une liste de choses que vous importez en bullet point
% seriesUS.xls                    Donnees americaines (format excel)
% filtreHP.m                      Script du filtre HP
% make_latex.m                    Faire des tableaux latex dans MATLAB
% ======================================================================= %
% OUTPUTS                         DESCRIPTION
% Une liste de choses que vous exportez, e.g. des figures ou des donnees.
% ======================================================================= %
% STRUCTURE
% C'est bien de donner l'aborescence de votre dossier de travail. Comme ca,
% tout le monde peut verifier qu'il ne manque rien et que tout est a sa
% place.
% MATLAB
% |--- 00_prog
% |--- 10_data
% |--- 20_tools
% |--- 30_output
% ======================================================================= %
%% 0. Initialisation
% ======================================================================= %

% Note: "%" introduit un commentaire. MATLAB passe par dessus sans les lire
% comme des lignes de commandes. Ils peuvent etre utilises en debut ou au
% milieu des lignes. "%%" en debut de ligne introduit une section. C'est
% utile parce qu'un peut lancer une section complete de commandes dans
% MATLAB avec le boutton "Run Section" dans l'onglet "Editor" ci-haut.

% Note: Pour lancer une ligne ou plusieurs lignes, selectionnez ce que vous
% voulez lancer et appuyez sur F9.

clear;     % Pour effacer tout de la memoire
close all; % Pour fermer (toutes) les figures ouvertes
clc;       % Pour effacer votre command window

% Pour commencer, nous allons definir le chemin complet vers le dossier de 
% travail comme repertoire de travail (current directory).

cd(['/home/stephane/Dropbox/', ...
    'Introduction_aux_logiciels_de_calculs/MATLAB']);

cd( '/home/stephane/Dropbox/Introduction_aux_logiciels_de_calculs/MATLAB' );

% LA CONCATENATION
% J'ai fait expres de couper les mots au milieu pour introduire d'autres
% outils utiles. Les "[", "]" sont des operateurs de concatenation. En
% gros, ca colle deux objets ensembles. Les apostrophes "'" indiquent que
% le contenu sont des chaines de caracteres (strings). La virgule "," est
% la facon MATLAB de dire qu'on change de colonne dans une matrice. Dans le
% contexte, ca veut dire qu'on colle les objets horizontales pour en faire
% un seul. Les trois points "..." indiquent a MATLAB que la commande n'est
% pas terminee et es points virgules ";" supriment l'affichage.

% Un des interet est de ne pas depasser 80 caracteres (le ligne verticale) 
% parce que 80 caracteres de large peuvent entrer sur une feuille 8.5x11 in
% pour etre imprimes, s'il y a besoin. D'autres usages de ces outils vont
% suivrent plus bas.

% LES CHEMINS RELATIFS
% L'idee est qu'on va souvent importer et exporter beaucoup de choses et on
% aimerait pouvoir mettre a jour tous les chemins si jamais on deplace le
% dossier MATLAB ailleurs en changeant UNE SEULE LIGNE (ci haut, 50 et 51).
% Pour le faire, on definit les chemins vers le dossier de donnee (10_data)
% et les autres a partir de l'interieur du dossier de travail. Dans MATLAB,
% on peut le faire en creant une STRUCTURE contenant comme entree tous les
% dossiers contenus dans MATLAB.

paths.dat = '10_data/';
paths.too = '20_tools/';
paths.out = '30_output/';

% LES STRUCTURES
% Les structures sont des objets MATLAB qui peuvent contenir ce que vous
% voulez, y compris d'autres structures, des matrices, des cellules (on
% verra plus loin), etc. Le nom que vous voyez dans votre environement de
% travail (Workspace) est "paths" ici. Le point "." est la facon d'indicer,
% c.a.d. d'aller cherche les differents champs dans la structure.

paths % Ceci affice l'objet dans votre fenetre de commande (Command Window)
% Et la couleur orange sous le nom indique que MATLAB vous fait un
% suggestion. Si vous suivez la suggestion:
paths; % Rien n'apparait parce que le point virgule suprime l'affichage. Si
% la couleur orange vous trouble, la fonction display est la bonne facon
% d'afficher le contenu de "paths":
disp(paths);

% NB: Quand les structures sont complexes, rien ne vous empeche d'ajouter
% des notes:
paths.desc = 'Ceci est une note importante';
disp(paths.desc);
% Et vous pouvez suprimer des champs si vous ne les voulez plus:
paths = rmfield(paths, 'desc');
disp(paths);
% Le premier argument est la structure et, le second, le nom du champs que
% vous voulez enlever. 

% AJOUT DES FONCTIONS IMPORTANTES
% On peut creer des fonctions personalisees dans MATLAB. Pour le faire il
% faut les mettre dans un script individuel avec un nom correspondant au
% nom donne a la fonction. Ici, je vous en donne quelques-unes. Pour s'en
% servir, il faut que MATLAB sache ou chercher:
addpath(paths.too);
% Les dossiers accessibles pour leurs fonctions ne sont pas transparents
% a gauche dans le contenu affiche du dossier courant (Current Folder).

% Note: Si vous cherchez quelque chose:
% 1. dans la fenetre de commande (Command Window) entrez "help" (sans
% guillemets) suivi d'un espace et du nom d'une fonction. E.g.:
help ones
% 2. sinon le site de Mathworks est aussi une bonne reference:
% https://www.mathworks.com/help/matlab/ref/ones.html
% 3. Google
% 4. Quand vous aurez fait le tour, ensuite vous pouvez vous permettre de
% demander a quelqu'un en personne.
% ======================================================================= %
%% 1. Importation de donnees
% ======================================================================= %

% MATLAB peut importer beaucoup de types de fichiers. Il se peut que les
% choses aillent mal. Ne paniquez-pas, c'est souvent un probleme de
% format (string vs doubles). Vous pouvez souvent regler le probleme en
% utilisant d'autres fonctions.

% Vous allez voir un exemple d'utilisation de chemins relatifs dans MATLAB 
% ci-bas. Notez que j'utilise 'try/end': en principe, ca ne marche pas. Le
% but est de vous donner un exemple de comment empecher MATLAB d'arreter
% sur une erreur.
try
    d.data = xlsread([paths.dat, 'seriesUS.xls']);
catch   
    warning(sprintf('\nERROR. ;)'));
end
% Que faire?
% 1. Vous pouvez generez un script d'importation avec l'icone
% d'importation. Il y a une option 'generate script';
% 2. Vous utilisez une fonction plus simple que xlsread et vous contournez
% le probleme vous-meme.

%
d.data = readtable([paths.dat, 'seriesUS.xls']);
% Ceci fonctionne habituellement, mais il va falloir travailler un peu pour
% tout mettre dans le bon format.

d.mat = table2array(d.data(:,4:end));
% Nous obtenons seulement la matrice des observations. Notez comment se
% fait l'indexation: on peut utiliser 'end', on indique une sequence de 4 a
% la fin par saut de 1 avec 4:end, les dimensions sont en ordre et
% contenues entre des parantheses collees sur le nomde l'objet et les deux
% points (:) servent aussi a dire 'prendre tout.'

% ======================================================================= %
%% 2. Calculs de statistiques sur les donnes americaines
% ======================================================================= %

% NB: Si vous voulez voir les figures dans MATLAB, ne lancez pas la
% commande close en meme temps que les lignes qui creent les figures.

% Note:
% Une serie stationnaire (du second ordre) est telle que ses deux
% premier moments indconditionels existent et sont constants. En d'autres
% mots, l'esperance est toujours la meme, la variance est toujours la meme
% et l'autocovariance est toujours la meme pour tous les retards
% consideres. Ce n'est pas le cas du PIB americain.

% La decomposition que nous allons choisir n'est pas unique, elle pose 
% probleme, mais elle a ete beaucoup utilisee. Si cela vous interesse, 
% allez lire:

% Hamilton, James D. (2018). 'Why You Should Never Use the Hodrick-Prescott
% Filter', Review of Economics and Statistics, 100(5), p.831-843.

% COMMENT FILTRER DES DONNEES
% Idee: x = x_c + x_t (somme de deux composantes)
% J'aimerais connaitre, par exemple, sd(x_c), mais ceci depend de l'echelle
% de ma variable. Pour eviter cela, je dois choisir une normalisation. On
% choisit la suivante: 
% x_c/x_t = (x - x_t)/x_t ~ ln(x) - ln(x_t) quand x_c est petit.

% C'est pour cette raison que nous prenons le logarithme AVANT de filtrer
% et que nous travaillons typiquement avec une volatilite en 'pourcentage':
% 100*sd(x_c/x_t).

hp.gdp = log(d.mat(:,1)); % l'operation est vectorisee
% Si vous voulez voir de quoi ceci a l'air:
hp.dates = table2array(d.data(:,3));
plot(hp.dates,hp.gdp);
close;

% Avant d'appliquer le filtre, il faut s'assurer qu'il n'y a pas de valeurs
% manquantes. La fonction isnan() identifie par 'vraie' (1) les valeurs
% manquantes d'une matrice.
hp.index{1} = find(isnan(hp.gdp));
hp.gdp(hp.index{1}) = []; % Truc pour laisser tomber des observations

% Note: Les crochets "{}" est la methode pour indicer ce qu'on appelle des
% cellules (cell arrays). C'est une version plus versatile des matrices.
% Une matrice contient soit entierement des chaines de caracteres, soit
% entierement des nombres (doubles ou integers). Une cellule peut contenir
% les deux a la fois, par exemple.

lambda = 1600; % Donnees trimestrielle

% On retire la composante tendantielle
hp.gdp = hp.gdp - filtreHP(hp.gdp, lambda); 
% Nous pouvons regarder ce que cela donne visuellement:
hp.comp{1} = setdiff(1:size(d.data(:,1)), hp.index{1}); % Date pour le PIB
plot(hp.dates(hp.comp{1}), hp.gdp);
close;

% Note:
% La fonction filtreHP() admet une matrice, alors vous pourriez, en
% faisant attention, appliquer la fonction une seule fois a toutes vos
% donnees, a condition que le panel soit balance.
hp.c = log(d.mat(:,2)); % La consommation
hp.index{2} = find(isnan(hp.c));
hp.c(hp.index{2}) = [];
hp.c = hp.c - filtreHP(hp.c,lambda);
hp.comp{2} = setdiff(1:size(d.data(:,1)), hp.index{2});

% Voici un exemple d'une commande conditionnelle. Si la condition est
% vraie, la commande s'execute. Sinon, MATLAB passe par dessus.
if isequal(hp.index{:}) 
    plot(hp.dates(hp.comp{1}), hp.gdp);
    hold on;
    plot(hp.dates(hp.comp{1}),hp.c);
    legend('PIB', 'Consommation');
    hold off;
end
close all; % Si jamais, il y en a plusieurs.

% Calculons quelques statistiques:
hp.stat = nan(8,1);
hp.stat(1,1) = corr(hp.gdp, hp.c);
hp.stat(2,1) = 100*std(hp.gdp);
hp.stat(3,1) = std(hp.c)/std(hp.gdp);
% Il s'agit ici d'une boucle "for". L'idee est que "i" sera successivement
% fixe a chaque valeur dans la sequence 1:5 (1 a 5 par saut de 1). Pour
% chaque cas, les commandes seront executees UNE A LA SUITE DE L'AUTRE. Il
% existe d'autres types de boucles (while, parfor), mais je n'en ferai pas
% d'autres ici.

for i=1:5
    % Pour les retards, on perd les observation les plus reventes, donc
    % celle qui se trouvent a la fin.
    hp.stat(i+3,1) = corr(hp.gdp(1:end-i),...
                          hp.gdp(1+i:end));
end

% Une autre facon de faire est d'utiliser 'autocorr'. Attention: certaines
% fonctions divise par N observations et, d'autres' par N-1.

% Faisons un exemple de tableau
hp.rows = cell(8,1);
hp.rows{1} = '$\rho(PIB_t, C_t)$';
hp.rows{2} = '$\sigma(PIB_t)$';
hp.rows{3} = '$\sigma(PIB_t)/\sigma(C_t)$';
for i=1:5
   hp.rows{i+3} = ['$\rho(PIB_t, PIB_{', num2str(i), '})$'];
end

hp.t1.options = {'row', hp.rows', ...
           'col', {'Donnees US'}, ...
           'multicol', false, ...
           'title', 'Statistiques: un exemple', ...
           'french_dec', true, ...
           'notes', 'Exemple de notes', ...
           'save', true, ...
           'f_name', [paths.out, 'example'], ...
           'dec', 3};
hp.t1 = make_latex(num2cell(hp.stat), hp.t1.options{:});
disp(hp.t1.table);

% Il y a d'autres facons de filtrer les donnees. Par exemple, on peut
% prendre un polynome du temps et estimer par MCO.

[pol.T,~] = size(hp.gdp); % Plusieurs fonction renvoient un ensemble de 
                          % de resultats. Il est possible d'aller chercher
                          % seulement les resultats pertinents de cette
                          % facon.
pol.x = NaN(pol.T,10); % Prenons un polynome d'ordre 9
pol.x(:,1) = 1; % Une constante
for i=1:9
   pol.x(:,i+1) = (1:pol.T).^i; % Le point applique l'operation une entree
end                             % a la fois.

% Les residus de la regression est la composante cyclique:
X = pol.x;
Y = log(d.mat(hp.comp{1},2)); % N'oubliez pas d'enlever les NaN
pol.gdp = (eye(pol.T) - X*((X'*X)\X'))*Y;

% Comparons:
plot(hp.dates(hp.comp{1}), hp.gdp);
    hold on;
    plot(hp.dates(hp.comp{1}), pol.gdp);
    a = findobj(gca, 'Type', 'line'); % Omettre les bandes de la legende
    recessionplot;
    legend([a(1), a(2)], 'HP', '9e deg.');
    hold off;
    print([paths.out, 'exemple_figure'], '-dpng');
close;
% La magie de recessionplot fonctionne seulement pour les dates du NBER. Si
% vous voulez le faire pour d'autres dates ou d'autres pays, vous aller
% devoir fouiller pour trouver comment fonctionne 'patch' ou modifier le
% code source de recessionplot.

% ======================================================================= %
%% 4. Un mot sur la programmation en economie
% ======================================================================= %

% Maintenant, vous avez des exemples de commenter importer des donnees,
% fouiller pour des informations, utiliser des matrices, faire des boucles,
% faire et exporter des graphiques, ainsi que de construire des tableaux
% LATEX avec make_latex. En principe, si quelqu'un vous demande de faire un
% Travail Pratique avec MATLAB, vous etes capables de trouver comment faire
% le travail ET, TRES IMPORTANT, sortir les results dans un format qui se
% presente proprement. 

% Les autres scripts dans 00_prog sont des exercices avec les corriges. 
% Vous pouvez faire comme vous voulez, mais il y a une seule facon
% d'apprendre a programmer et c'est de vous casser la tete pour trouver
% comment faire les choses vous-meme. C'est aussi impossible de passer tous
% les cours de premiere annee du doctorat ou de maitrise a l'ESG sans
% savoir programmer au moins un peu.

% CONSEIL: Profitez du fait que vous etes moins occupes en debut de session
% qu'en milieu de session pour vous familiariser avec les logiciels tout de
% suite.