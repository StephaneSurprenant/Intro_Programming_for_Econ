%
% Auteur: Stephane Surprenant, UQAM
% Creation: 04/08/2019
%
% Description: Vous avez surement vu dans un cours de statistique ou
% d'econometrie plusieurs proprietes de l'estimateur OLS. Dans ce script,
% je vous montre comment on peut utiliser des simulations pour avoir une
% idee de ce que ceci implique quand on a un nombre fini d'observations, ou
% quand les hypotheses sont violees (un peu ou beaucoup).
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
%% 1. Biais d'omission
% ======================================================================= %

% On veut montrer que violer l'hypothese E(e(i)|X) = 0 induit un biais.
% Puisque E(e|X) = 0 implique E(X'e) = 0 (attention: la converse n'est pas
% vraie), par contraposition, E(X'e) =/= 0 implique E(e|X) =/= 0.

% Un exemple commun est un modele avec une composante autoregressive. C'est
% le cas que nous allons etudie. Le modele est:
% y(t) = a + b*y(t-1) + e(t), e(t) ~ N(0,s^2).

% Nous ne sommes pas tenus d'imposer la normalite des erreurs, mais je dois
% choisir une distribution pour simuler. Pourquoi ceci viole E(e|X) = 0?
% Parce que la condition E(e|X) = 0 impose des restrictions croisees:
% y(3) = a + b * y(2) + e(3)
% y(2) = a + b * y(1) + e(2)
% Ici, ce qui est vrai est que E(e(t) | y(t-1), ..., y(0)) = 0. Par contre,
% ce n'est PAS VRAI que E(e(t) | y(t), ..., y(0)) = 0: si vous connaissez
% a,b,y(1) et y(2), vous connaissez aussi e(2) et, generalement, e(2) =/=0.

% On va comparer 3 valeurs de b et trois tailles d'echantillons. On aura
% donc 9 cas:

a = 1; s = 1;           % Ordonnee a l'origine et ecart-type
b = [0.1, 0.5, 0.99];
N = [100, 1000, 10000];

M = 100;       % On va lancer M simulations de chaque cas
K = size(b,2); % Nombre de b's differents
J = size(N,2); % Nombre de tailles differentes

beta = nan(M,J,K); % Pour collecter les coefficients de pente
burn = 100;        % C'est typique d'avoir quelques periodes qu'on jette
% pour limiter l'impact des conditions initiales sur les resultats.

y0     = a./(ones(1,K)-b); % Je vais commencer a l'esperance des processsus

rng(1234); % Pour que tout puisse etre reproduit
for jj = 1:J
    for kk = 1:K
        for ii = 1:M
            % On construit la series simulee
            series = ones(N(jj),1).*y0(kk);
            for tt = 2:(N(jj) + burn)
                series(tt) = a + b(kk)*series(tt-1) + s*randn(1);
            end
            % On laisse tomber le burn-in
            series(1:burn) = [];
            % On estime le parameter autoregressif (b) par OLS
            y = series(2:end);
            X = [ones(N(jj)-1,1), series(1:(end-1))];
            coef           = X\y;
            % On le place dans la matrice des betas
            beta(ii,jj,kk) = coef(2);
        end
    end
end

% On va calculer les biais. Ils sont definis comme b- E(bhat|X).
bias = nan(J,K);
for jj = 1:J
    for kk = 1:K
        bias(jj,kk) = b(kk) - mean(beta(:,jj,kk));
    end
end

% On va mettre les resultats dans une figure pour voir ce qui se passe.
close all;
plot(b, bias(1,:));
    hold on;
    for kk =2:K
        plot(b, bias(kk,:));
    end
    legend(['N: ', num2str(N(1))], ...
           ['N: ', num2str(N(2))], ...
           ['N: ', num2str(N(3))], 'Location', 'southwest');
    hold off;
    xlabel('Coefficient AR');
    ylabel('Biais');
print([paths.out, 'Biais_OLS_sur_AR(1)'], '-dpng');
close;

% Quand l'echantillon est petit relativement a la taille du bruit, des
% donnes plus persistantes peuvent induire des biais plus grand.


% ======================================================================= %
%% 2. Exercice: la taille du test
% ======================================================================= %

% On veut savoir si vous avez vraiment 5 % de chance de rejetter H0 quand
% vous tester pour b=0. Pour ce faire, on va simuler un modele lineaire:
% y(i) = a + b*x(i) + e(i), e(i) ~ N(0,s)
% x(i) ~ N(m,sx);

% On a des individus, donc il n'y a plus de dependence temporelle et on
% veut imposer que E(e|X) = 0. En principe, quand N --> infini, on a que la
% statistique:
% t := (bhat - 0)/sqrt(vhat(bhat)) ~ N(0,1), si on suppose que vous avez un
% estimateur convergent de la variance de l'estimateur employe pour
% calculer bhat.
% NB: pas besoin de burn-in quand on n'a pas de dependence temporelle.

% On travailler avec les tailles 100, 1000 et 10000 comme ci-haut. Par

% contre, on va utiliser un seul ensemble de parametre a et b. On va
% simplement comparer 2 cas: homoscedasticite et heteroscedasticite.

N = [100, 1000, 10000];
a = 1;
b = 0;   % On veut que H0 soit vraie si on veut valider la taille du test!
m  = 3;  % Moyenne de X
sx = 15; % Ecart-type de X

% Pour s, vous allez avoir deux cas. Le premier (homoscadastique) consiste
% a lui fixer la meme valeur pour tout le monde. Le second
% (heteroscedastique) consiste a faire varier s a travers les individus.

% Un facon de faire cela serait d'inclure au bon endroit dans vos boucles
% un s cree comme suit:
s      = ones(N(1), 2);       % s = 1 versus s = exp((x-m)/sx)
x      = m + sx*randn(N(1),1);% On a besoin de x pour calculer exp(x)!
s(:,2) = exp((x-m)/sx);
% Ensuite, dans votre boucle vous allez creer des y de la facon suivante:
y = nan(N(1),1);
for ii = 1:N(1)
   y(ii) = a + b*x(ii) + s(ii,2)*randn(1); 
end
% Evidemment, a vous de faire les ajustements pour que N change et que s
% change aussi.

% Ensuite, on utilise l'echantillon pour estimer b par OLS, on construit la
% statistique t. C'est la statistique t qu'on garde dans une matrice cette
% fois-ci. Le but: en principe, environ 5% de vos simulations devrait
% avoir:
% abs(t) >= abs(norminv(0.025))
% En gros, vous prenez la moyenne de cette condition logique a travers les
% simulations, pour s et N donnes pour savoir si ca marche ou pas.

% En principe, vous devriez aussi tomber plus proche de 5% quand N augmente
% parce que le test repose sur un argument de convergence asymptotique. Je
% vous conseille de tenter le coup... Ca ressemble etrangement a des
% travaux pratique du department dans le cours ECO7036 Econometrie. ;D.
% Evidemment, ca ne devrait pas bien marcher pour le cas heteroscedastique.

% Une fois que vous avez coder la simulation, trouvez une facon
% intelligente de presenter vos resultats. Tableaux LATEX et/ou figures qui
% peuvent etre histogrammes, des courbes ou autres. 