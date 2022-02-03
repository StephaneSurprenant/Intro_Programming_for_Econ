#
# Auteur: Stephane Surprenant, UQAM
# Creation: 02/08/2019
#
# NB: Je deconseille l'utilisation d'accent dans les commentaires.
#
# Description:
# Ceci est un script R. Le but est de vous introduire a l'utilisation 
# de ce logiciel. Une partie du travail consiste a vous donnez un exemple 
# de bonnes habitudes de travail, comme ajouter des commentaires comme
# ceux-ci, utiliser une en-tête et utiliser des chemins relatifs.
#
# Ce fichier couvre vraiment la base. Le but est de vous donnez une idee du
# fonctionnement et de comment fouiller quand vous ne savez pas comment
# faire quelquechose. Les scripts R reprennent les exercices fait avec 
# MATLAB.
#
# Modificationns:
# 1. Entrez d'eventuelles mises à jour
# =========================================================================== #
# INPUTS                          DESCRIPTION
# Une liste de choses que vous importez en bullet point
# seriesUS.xls                    Donnees americaines (format excel)
# filtreHP.R                      Script du filtre HP
# make_latex.R                    Faire des tableaux latex dans R
# =========================================================================== #
# OUTPUTS                         DESCRIPTION
# Une liste de choses que vous exportez, e.g. des figures ou des donnees.
# =========================================================================== #
# STRUCTURE
# C'est bien de donner l'aborescence de votre dossier de travail. Comme ca,
# tout le monde peut verifier qu'il ne manque rien et que tout est a sa
# place.
# R
# |--- 00_prog
# |--- 10_data
# |--- 20_tools
# |--- 30_output
# =========================================================================== #
# 0. Initialisation ----
# =========================================================================== #

rm(list=ls()) # Pour tout effacer

# NB: Contrairement a MATLAB ou encore STATA, dans R il faut charger les
# bibliotheques (libraries) en memoire avant de pouvoir se servir de
# certaines fonctions. C'est la meme chose avec Python, par exemple.

# Si jamais il vous manque une ou plusieurs libraires, vous pouvez les 
# installer avec la fonction instal.packages("nom_du_package").

library(dplyr)    # Utile pour le "piping" operator %>%
library(ggplot2)  # fonctions graphiques TRES puissantes
library(reshape2) # permet d'ajuster le format des donnees
library(readxl)   # Pour importer les donnees

# Ensuite, les fonctions sont des objets dans R. Vous pouvez les coder
# directement dans votre script ou les coder dans un autre script et
# simplement utiliser la fonction source() pour crer la fonction. C'est ce 
# je fais habituelle.

# NB: les commandes peuvent se lancer en utilisant CTRL + ENTER pour lancer la
# selection et SHIFT+CTRL+ENTER pour lancer tout le script courant.

# NB: Dans R, on peut faire des assignations avec le symbole d'egalite (=) ou
# encore avec une fleche (<-). Le second est plus typique.

# On choisir le repertoire de travail (working directory)
# wd <- paste("/home/stephane/Dropbox/Introduction_aux_logiciels_de_calculs", 
#             "R", sep="/")
wd <- "/home/stephane/Dropbox/Introduction_aux_logiciels_de_calculs/R"
setwd(wd)

# Comme vous voyez, R permet de couper les commandes a peu pres comme vous
# le voulez. Ensuite, les fonctions R permettent d'entrer des arguments de 2
# facon: par localisation (comme dans MATLAB, vous mettez les choses dans le
# bon ordre) et par identification (dans MATLAB, ca se fait avec des 'name-
# pair-values') en indiquant le nom de l'argument et en assignant une valeur
# avec le signe d'egalite. C'est un raison pourquoi je prefere ne pas assigner
# d'objets avec l'egalite: pour rendre le code lisible.

# Conseil: utilisez les noms d'argument quand il y a plus de 2 ou 3 pour 
# faciliter la lecture.

# Comme avec MATLAB, la bonne facon de travailler est d'utiliser des chemins
# relatifs. On la le faire avec une liste. Les listes R sont un peu comme les
# cellules MATLAB: elles peuvent contenir un melange de plusieurs choses, y 
# compris d'autres listes. Elles sont aussi comme les structures MATLAB parce
# que les entrees peuvent avoir des noms.

paths <- list(dat = "10_data",
              too = "20_tools",
              out = "30_output")

print(paths) # On peut voir le contenu, si on veut. On remarque les noms sont
# accessibles avec nom_de_liste$nom_de_variable. Par exemple:
print(paths$dat)

source(paste(paths$too, "filtreHP.R", sep="/"))
source(paste(paths$too, "make_latex.R", sep="/"))

# =========================================================================== #
# 1. Importation des donnees ----
# =========================================================================== #

# Remarquez que 4 tirets l'un a la suite de l'autre sont une facon de laisser
# savoir a RStudio qu'on commence une section. On peut y acceder juste en haut
# de la console. Quand on a >1000 lignes de code, c'est utile de pouvoir sauter
# a la bonne section.

data <- read_xls(paste(paths$dat, "seriesUS.xls", sep="/")) %>% as.data.frame()

# Le %>% est appele un "piping operateur". Il passe l'objet precedent comme
# premier argument de la fonction suivante: ici, on convertit l'output de 
# read_xls en dataframe, un type de liste qui peut contenir plusieurs types de
# variables. En gros, c'est une facon simple d'avoir un tableau.

head(data, n=6) # Les 6 premieres lignes
tail(data, n=6) # Les 6 dernieres lignes
names(data)     # Tous les noms

# NB: Contrairement a MATLAB, R permet d'operer directement sur l'output des
# fonction. Par exemple
head(data, n=6)[1,]
# Donne la premiere ligne seulement. Notez aussi que les matrices et les 
# dataframes s'indexent par des crochets plutot que des parentheses dans R.

# =========================================================================== #
# 2. Calculs de statistiques sur les donnes americaines ----
# =========================================================================== #

# Note:
# Une serie stationnaire (du second ordre) est telle que ses deux
# premier moments indconditionels existent et sont constants. En d'autres
# mots, l'esperance est toujours la meme, la variance est toujours la meme
# et l'autocovariance est toujours la meme pour tous les retards
# consideres. Ce n'est pas le cas du PIB americain.

# La decomposition que nous allons choisir n'est pas unique, elle pose 
# probleme, mais elle a ete beaucoup utilisee. Si cela vous interesse, 
# allez lire:

# Hamilton, James D. (2018). 'Why You Should Never Use the Hodrick-Prescott
# Filter', Review of Economics and Statistics, 100(5), p.831-843.

# COMMENT FILTRER DES DONNEES
# Idee: x = x_c + x_t (somme de deux composantes)
# J'aimerais connaitre, par exemple, sd(x_c), mais ceci depend de l'echelle
# de ma variable. Pour eviter cela, je dois choisir une normalisation. On
# choisit la suivante: 
# x_c/x_t = (x - x_t)/x_t ~ ln(x) - ln(x_t) quand x_c est petit.

# C'est pour cette raison que nous prenons le logarithme AVANT de filtrer
# et que nous travaillons typiquement avec une volatilite en 'pourcentage':
# 100*sd(x_c/x_t).

hp <- log(data[,-c(1:3)])
# R permet les indices negatifs. La fonction c() cree un vecteur et 1:3 est
# la meme chose que dans MATLAB: il s'agit de la sequence 1,2,3. Les indices
# negatifs indique de prendre tout sauf les valeurs positives correspondantes.

# On a des donnees trimestrielles, alors le parametre de lissage du filtre est
# fixe a 1600. C'est la valeur par defaut de notre fonction. On veut garder la
# partie residuelle seulement:
index <- !is.na(hp)
for (jj in 1:dim(hp)[2]){
  hp[index[,jj],jj] <- as.numeric(filtreHP(y=hp[index[,jj],jj])$res)
}

# On va regarder de quoi nos resultats on l'air dans un graphique de ggplot.
# Le principe est le suivant: on ajoute des couches pour construire les
# figures et on a besoin d'un format long pour atomatiser plusieurs choses.

hp$Date        <- data$date
names(hp)[1:3] <- c("Real GDP", "Real Consumption", "Real Investment")
molten            <- melt(hp[,c(1:3,17)], id="Date")
names(molten)[-1] <- c("Series", "Value")

# Nous pouvons regarder de quoi a l'air le nouveau format
head(molten)

# Pour creer et sauvegarder le graphique, nous allons ouvrir une connection
# a un fichier png

png(file=paste(paths$out, "Cyclical_aggregates.png", sep="/"),
    width=7, height=5, units="in", res=350)

# Le graphique est un objet dans R. Bien qu'on ne soit pas oblige d'imprimer
# l'objet pour un seul graphique, si on effectuait une boucle, il faudrait le
# faire, alors je vous montre la bonne facon immediatement.

g <- ggplot(molten) + 
     geom_line(aes(x=Date, y=Value, color=Series)) +
     ylab("Cyclical component") + 
     xlab("") +
     scale_color_manual(values=c("#009E73","#E69F00","#0072B2",
                                 "#CC79A7","#000000")) +
     theme_bw() + theme(legend.position = "top")

print(g)

dev.off() # On coupe la connection. Dans ggplot(), j'inscris le dataframe
# du format voulu. Je veux un format long pour pouvoir automtiser l'affichage
# de 3 series. Ensuite, quand on met le dataframe directement dans ggplot(),
# son contenu faire partie de l'environnment a l'interne, alors on peut
# inscrire les noms de colonnes dans les autres parties de la commande. Aussi,
# geom_line() est une option parmis plusieurs (geom_bar, geom_point, etc.). Il
# faut choisir ce qu'on veut. Dans tous les cas aes() est pours aesthetics, 
# donc l'apparence du graphique. Si la variable associee a couleur est
# discrete, scale_color_manual() vous permet d'ajouter les couleurs que vous
# voulez. Finalement, theme_bw() est pour "black and white."

# EXERCICE: faites un graphique avec les deux mesures d'heures
# travaillees et sauvegarder-le.

# On va calculer quelques statistiques:
stats    <- array(NA, dim=c(8,1))

if (sum(index[,1] != index[,2]) == 0){
  x        <- index[,1]                     # On garde les memes lignes!
  stats[1] <- cor(hp$`Real GDP`[x], 
                  hp$`Real Consumption`[x]) # COR(Y,C)
  stats[2] <- 100*sd(hp$`Real GDP`[x])      # Volatilite du PIB
  stats[3] <- sd(hp$`Real Consumption`[x])/
              sd(hp$`Real GDP`[x])          # Vol. relative de la consommation
}

# On calcule ensuite quelques autocorrelations
y <- hp$`Real GDP`[x] 
N <- sum(x)
for (ii in 1:5){
  stats[ii+3] <- cor(y[1:(N-ii)], y[(1+ii):N])
}

# J'ai code rapidement une fonction R pour faire des tableau LATEX avec des
# dataframe. On va mettre nos resultats dans des tableaux.
stats <- as.data.frame(x=stats, row.names=c("COR(Y,C)",
                                            "Volatilite de (Y)",
                                            "Volatilite relative de C",
              sapply(1:5, function(ii){paste("AR (", ii, ")", sep="")})))
names(stats) <- "Statistiques du cycle américain"
# Ce bout semble complique, mais c'est simple. SAPPLY utilise une boucle a
# l'interne pour construire les 5 cas de AR (ii) et renvoit un vecteur qui
# se colle au reste des noms.

options <- list(title = "Exemple sur données américaines",
                notes = "Données HP filtrées.",
                multicol = "",
                size     = "")

make_latex(content=stats, options=options, 
           file_name=paste(paths$out, "Exemple_US.tex", sep="/"))

# Le tableau a l'air de ceci:
print(stats)
# Et le code LATEX de cela:
make_latex(content=stats, options=options)

# Il existe d'autres moyens de filtrer les donnes. Par exemple, on peut 
# regresser les variables sur des polynomes de temps.

ordre    <- 5
N            <- sum(index[,1])
polynome     <- array(NA, dim=c(N, ordre+1))
for (ii in 0:ordre){
  polynome[,ii+1] <- (1:N)^ii 
}

# Le residu de la regression est la composante cyclique
x <- index[,1] # Pour le PIB seulement
X <- polynome
Y <- hp$`Real GDP`[x] %>% as.matrix()

# NB: solve() peut etre capricieuse avec les matrices presque singulieres
# comme X'X dans notre cas. Si cela arrive, prenez une tolerance plus
# numerique plus petite.

gdp <- (diag(N) - X%*%solve(t(X)%*%X, tol=10^(-28))%*%t(X))%*%Y
gdp <- cbind.data.frame(hp$Date[x], gdp)
names(gdp) <- c("Date", names(hp)[1])

g <- ggplot(gdp) + geom_line(aes(x=Date, y=`Real GDP`)) +
     xlab("") + theme_bw()

print(g)

# EXERCICES 1. ----------------------------------------------------------------
# Introduisez une fonction pour filtrer les donnees par un polynome.
# Regardez attentivement la fonction filtreHP():
View(filtreHP)
# Une fonction R est un objet, donc elle est assignee a un nom comme suit:
# nom_de_la_fonction <- function(arguments){ 
#
# CALCULS QUELCONQUES AVEC arguments

# return(RESULTATS DES CALCULS)
#}
# L'idee ici est de coder une fonction qui va prendre pour argument une serie
# ainsi qu'un ordre polynomial: (series,ordre=5) pourrait etre un choix 
# d'arguments. Vous pouvez vous limitez a ce que la fonction renvoit seulement
# le residus (la partie cyclique) comme resultat. ATTENTION: R ne traite pas 
# les vecteurs et les matrices de la meme facon. Pour eviter tout probleme, je
# vous suggere d'inclure une ligne comme celle-ci:

# series <- as.matrix(series)

# Aussi, la plupart des fonctions n'exclus pas automatiquement les valeurs
# manquantes (sd(), mean() ont un argument na.rm pour na remove), alors ne
# soyez pas surprise si parfois vous obtenez des NA -- c'est habituellement que
# vous avez oublie un ou plusieurs NAs dans vos objets R.

# EXERCICE 2. -----------------------------------------------------------------
# Refaites le graphique sur les composantes cycliques HP filtrees, mais cette
# fois-ci, faites-le en filtrant les donnees par un polynome d'ordre 5.