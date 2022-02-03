%
% Auteur: Sephane Surprenant, UQAM
% Creation: 03/08/2019
%
% Description: Ce script vous donne un exemple de comment effectuer une
% course de modeles (backtesting ou pseudo-out-sample forecasting) pour
% comparer la capacite de differentes methodes pour prevoir des variables
% macroeconomiques.
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
%% 1. Importation de donnees
% ======================================================================= %

% On va etre originaux et on va importer des donnees directement de FRED
% (Federal Reserve Bank at Saint-Louis' Economic Database).

% Etablir un lien avec FRED
url = 'https://fred.stlouisfed.org/';
c = fred(url);
% Importation des series choisies
series = {'GDP'};
d = fetch(c, series);
close(c);

% NB: d est une structure. Cet objet contient tout ce dont vous avez besoin
% pour comprendre le contenu des series importees.

% Nous alons tenter de prevoir le taux de croissance moyen par trimestre du
% PIB nominal Americain sur deux horizons differents: 1 trimestres et 4
% trimestres. On commence par construire ces taux de croissance moyens:
horizon = [1,4];
growth  = nan(size(d.Data,1),size(horizon,2));

count = 1;
for h = horizon
    growth((1+h):end,count) = (log(d.Data((1+h):end,2)) - ...
                               log(d.Data(1:(end-h),2)))/h;
    count = count + 1 ;
end
% NB: Les observations recentes sont a la fin des matrices. Prenez une
% minute pour comprendre pourquoi les lignes ci-haut veulent dire:
% (ln(y(t)) - ln(y(t-h)))/h

% NB: Habituellement, vous devriez sauvegarder vos donnees brutes telles
% quelles avant de poursuivre.

% ======================================================================= %
%% 2. Course de modeles
% ======================================================================= %

% L'idee est que nous allons approximer les conditions sous lesquelles nous
% aurions utiliser les methodes de previsions dans le passe en diminuant la
% taille de notre echantillon -- i.e., quand on va prevoir 1996Q1 h=4
% trimestres a l'avance, on va utiliser les donnees jusqu'en 1995Q1, soit 4
% trimestres plus tot.

% On va faire ca pour chaque modele, chaque horizon, chaque variable et
% chaque periode entre 2007Q1 et la derniere observation disponible. Le but
% est que ca ne prenne pas trop de temps.

% Les modeles:
% AR DIRECT:
% gr(t) = a(h) + b(h)*gr(t-h) + e(t,h)
% C'est à dire qu'on va regresser le taux de croissance moyen sur sa valeur
% h periodes plus tot et une constante. Les (h) sont la pour insister sur
% le fait que les coefficients changent d'un horizon a l'autre.
% AR INDIRECT:
% gr(t) = a + b*gr(t-1) + e(t)
% Ici, on va utiliser la structure du modele pour extrapoler une prevision
% pour les horizons plus grand que 1. Puisque:
% grhat(t) = ahat + bhat*grhat(t-1)
% on peut iterer sur l'expression pour obtenir:
% grhat(t) = ahat +bhat(ahat +bhat*grhat(t-2))
% grhat(t) = ahat(1+bhat) + bhat^2 gr(t-2)
% ...
% grhat(t) = ahat(1+bhat+...+bhat^(h-1)) + bhat^h*gr(t-h)
% NB: gr(t-h) est connu.

% On commence par trouver 2007Q1. Les dates sont d.Data(:,1) sous forme de
% nombres (serial date numbers). Une solution est de les convertir. Une
% autre est de convertir 2007Q1 en nombre. Dans tous les cas, on veut que
% les deux soit compatible parce qu'on cherche avec des operateurs
% logiques:
start = find(d.Data(:,1) == datenum('2007Q1', 'YYYYQQ'));
start = start - max(horizon); % On va laisser tomber des observations au
% debut.

% Le POOS (pseudo-out-of-sample)
growth(1:max(horizon),:) = []; % On laisse tomber les NaNs
[final,K] = size(growth);      % On recupere les dimensions
forecasts = nan(final,K,K);    % On initialise une matrice pour garder les
                               % previsions: temps x horizon x modele.

for tt = start:final  % Temps
    count = 1;
    for h = horizon   % Horizon
        % In-sample: les donnees jusqu'en t-h
        train = growth(1:(tt-h),count);

        % Estimation
        y = train((1+h):end);
        N = size(y,1);
        X = [ones(N,1), train(1:(end-h))];
        bhat = X\y;

        % Previsions
        forecasts(tt,count,1)     = [1, train(end)]*bhat; % DIRECT
        if h == 1
            forecasts(tt,1,2) = [1, train(end)]*bhat; % INDIRECT h=1
            forecasts(tt,2,2) = bhat(1)*sum(bhat(2).^(0:3)) + ...
                                (bhat(2)^4)*train(end);
        end
        count = count + 1;
    end
end

% NB: L'Exercice ci-haut est fait avec une fenetre grandissante (expanding 
% window). Ceci veut simplement dire que l'echantillon utiliser pour 
% estimer les parametres des modeles croit dans le temps. Une autre facon
% de faire serait de laisser tomber une observation au debut de
% l'echantillon quand on en ajoute une a la fin. On parle alors d'une
% fenetre glissante (slidding window).

% ======================================================================= %
%% 3. Resultats
% ======================================================================= %

% On va produire les figures pertinentes et les sauvegarder dans
% '30_output'.

close;
dates = d.Data((end-60):end,1);
for jj = 1:2 % Horizon
   % Ajuster la dimension temporelle
   data  = forecasts((end-60):end,jj,:); 
   data2 = growth((end-60):end,:);
   
   % Ligne vertical dans le graphique
   x = find(dates == datenum('2007Q1', 'YYYYQQ'));
   y = data2(:,jj);
   h = horizon(jj);
   
   % Construction de la figure
   plot(dates, y);
   datetick('x', 'YYYY');
   axis tight;
   hold on;
   plot(dates, data(:,1)); % AR DIRECTE
   plot(dates, data(:,2)); % AR INDIRECTE
   line([dates(x), dates(x)], [min(y), max(y)], ...
        'color', 'k', 'Linestyle', '-.');
   legend(['Taux de croissance moyen (', num2str(h), ')'], ...
          ['DIRECTE (', num2str(h), ')']', ...
          ['INDIRECTE (', num2str(h), ')'], ...
          'Location', 'southeast');
   hold off;
   print([paths.out, 'Exemple_POOS_', num2str(h)], '-dpng');
   close;
end
% NB: On pourrait jouer sur les figures pour ajuster les etiquettes sur
% l'axe Y dans le second graphique de sorte a eviter d'avoir une notation
% scientifique, mais je ne le fais pas ici.

% A partir d'ici, vous pouvez aussi construire les erreurs de prevision
% hors echantillon et calculer toutes les statistiques que vous voulez.

% ======================================================================= %
%% 4. Exercices
% ======================================================================= %

% 4.1
% Refaites cet exercice, mais cette fois-ci avec un modele different. Par
% exemple, vous pourriez faire un modele du type suivant:
% gr(t) = a(h) + b(h)*gr(t-h) + d(h)*X(t-h) + e(t)

% ETAPES:
% 1. Vous allez chercher sur FRED la variable suivante:
% USREC
% Elle indique les dates de recessions selon le NBER en frequence mensuel.
%
% 2. Vous devez la convertir en frequence trimestrielle. Ca veut simplement
% dire que vous allez utiliser Q1=mars, Q2=juin, Q3=septembre, Q4=decembre.
% Le GDP comment en 1947Q1, donc vous trouvez mars 1947 dans ce que vous
% avez importer. S'il s'agit de a ligne 38 (aucun rapport), vous pouvez
% recuperer tous les mois dans un sequence avec sauts de 3 mois en
% utilisant 3:38:end pour indexer les bonnes lignes.
% 
% 3. Une fois que vous avez les recessions en trimestriel, vous allez
% ajuster les dimensions. On laisse tomber 4 periodes parce qu'on a des
% taux de croissances moyens sur 4 trimestres. Ensuite, il faut vous
% assurez que GDP et USREC en trimestriel finissent au meme moment. Il se
% peut que USREC finisse plus tard. Si oui, laisser tomber les observations
% de trop de USREC.
%
% 4. Vous n'avez qu'a estimer le modele ci-haut par OLS dans le meme genre
% de boucle que j'ai codee plus haut. Vous pourriez reprendre le meme code
% a ceci pres que vous avez besoin d'une troisieme position pour la
% dimension "modele" et que, evidemment, il faut faire la bonne regression
% pour ce 3e type de modele.

% 4.2.
% Presenter les resultats de l'exercice ci-haut sous forme de figure.

% 4.3.
% Refaites l'exemple que je vous ai donne plus haut, mais cette fois-ci,
% faites-le avec une fenetre glissante. Ca veut dire que quand tt=start,
% vous commencez avec l'observation 1, quand tt=start+1, vous laissez
% tomber l'observation 1 et ainsi de suite.

% 4.4.
% Comparez les resultats en expanding et slidding windows.