#
# Auteur: Sephane Surprenant, UQAM
# Creation: 05/08/2019
#
# Description: Ce script vous donne un exemple de comment effectuer une
# course de modeles (backtesting ou pseudo-out-sample forecasting) pour
# comparer la capacite de differentes methodes pour prevoir des variables
# macroeconomiques.
#
# =========================================================================== #
# 0. Initialisation ----
# =========================================================================== #

rm(list=ls()) # Pour tout effacer

# On choisir le repertoire de travail (working directory)
wd <- paste("/home/stephane/Dropbox/Introduction_aux_logiciels_de_calculs", 
            "R", sep="/")
setwd(wd)

library(dplyr)    # Utile pour le "piping" operator %>%
library(ggplot2)  # fonctions graphiques TRES puissantes
library(quantmod) # Permet d'importer des donnees
library(reshape2)

# NB: Si vous avez une erreure, vous pouvez installer les packages comme suit:
# install.packages("nom_du_package")
# Vous pourriez aussi automatiser la procedure, mais je voulais garder le code
# simple.

# On introduit une liste pour utiliser des chemins relatifs
paths <- list(dat = "10_data",
              too = "20_tools",
              out = "30_output")

# Un exemple de fonction qui permet de faire des tableau LATEX dans R
source(paste(paths$too, "make_latex.R", sep="/"))

# Attention: c'est une version simplifiee de la fonction MATLAB que j'ai faite.

# =========================================================================== #
# 1. Importation des donnees ----
# =========================================================================== #

# On va etre originaux et on va importer des donnees directement de FRED
# (Federal Reserve Bank at Saint-Louis' Economic Database).

# Vous pouvez allez fouiler a la main sur FRED, si vous voulez:
# https://fred.stlouisfed.org/series/GDPC1

# Prenons le PIB reel Us, plutot que le PIB US pour faire changement:
gdp <- getSymbols(Symbols = "GDPC1",
                  src     = "FRED",
                  auto.assign = F) %>% as.data.frame()

# Auto.assign empeche la fonction d'assigner la serie a un objet par elle-meme.
# Le format que renvoit getSymbols() assigne les dates aux noms de lignes. On
# va en faire une variable en soi dans notre dataframe pour quand on fera des
# figures plus tard.

N          <- dim(gdp)[1]
gdp        <- cbind.data.frame(as.Date(rownames(gdp)), gdp)
names(gdp) <- c("Date", "PIB")
rownames(gdp) <- 1:N

# Regardez de quoi nos donnees ont l'air pour le moment:
head(gdp)

# Pour les fin de prevision, nous allons travailler a partir du taux de
# croissance trimestriel moyen pour les horizons de 1 trimestres et de 4
# trimestres.

gdp <- cbind.data.frame(gdp, 
                        c(NA, diff(log(gdp$PIB), lag=1, difference=1)),
                        c(rep(NA,4), diff(log(gdp$PIB), lag=4, difference=1)/4))
names(gdp)[3:4] <- c("Croissance(h1)", "Croissance(h4)")

# On va couper les valeurs manquantes
gdp <- gdp[sapply(1:N, function(ii){sum(is.na(gdp[ii,])) == 0}),]

# =========================================================================== #
# 2. Course de modeles ----
# =========================================================================== #

# L'idee est que nous allons approximer les conditions sous lesquelles nous
# aurions utiliser les methodes de previsions dans le passe en diminuant la
# taille de notre echantillon -- i.e., quand on va prevoir 1996Q1 h=4
# trimestres a l'avance, on va utiliser les donnees jusqu'en 1995Q1, soit 4
# trimestres plus tot.

# On va faire ca pour chaque modele, chaque horizon, chaque variable et
# chaque periode entre 2007Q1 et la derniere observation disponible. Le but
# est que ca ne prenne pas trop de temps.

# Les modeles:
# AR DIRECTE:
# gr(t) = a(h) + b(h)*gr(t-h) + e(t,h)
# C'est a dire qu'on va regresser le taux de croissance moyen sur sa valeur
# h periodes plus tot et une constante. Les (h) sont la pour insister sur
# le fait que les coefficients changent d'un horizon a l'autre.

# AR INDIRECTE:
# gr(t) = a + b*gr(t-1) + e(t)
# Ici, on va utiliser la structure du modele pour extrapoler une prevision
# pour les horizons plus grand que 1. Puisque:
  # grhat(t) = ahat + bhat*grhat(t-1)
# on peut iterer sur l'expression pour obtenir:
# grhat(t) = ahat +bhat(ahat +bhat*grhat(t-2))
# grhat(t) = ahat(1+bhat) + bhat^2 gr(t-2)
# ...
# grhat(t) = ahat(1+bhat+...+bhat^(h-1)) + bhat^h*gr(t-h)
# NB: gr(t-h) est connu.

# On commence par trouver 2007Q1:
start  <- which(gdp$Date == as.Date("2007-01-01"))
finish <- dim(gdp)[1]

# On a besoin d'une matrice pour collecter les previsions:
forecast <- array(NA, dim=c(finish,2,2))
# On a #finish periodes x 2 horizons x 2 modeles et une seule variable

for (tt in start:finish){
  count <- 1
  for (h in c(1,4)){
    # On commence par limiter notre echantillon pour l'estimation
    train <- gdp[1:(tt-h),2+count] # Position de la variable a prevoir
    N     <- tt-h
    
    # On estime les parametres
    y <- train[(1+h):N]
    X <- cbind(1, train[1:(N-h)])
    bhat <- solve(t(X)%*%X)%*%t(X)%*%y
    
    # On effectue les previsions hors echantillon (i.e., on prevoit y(tt))
    # avec chaque modele:
    forecast[tt,count,1] = cbind(1, train[N])%*%bhat # DIRECT
    
    # Avec INDIRECT, on utilise le meme modele pour h=1 et on extrapole
    if (h==1){
      forecast[tt,1,2] <- forecast[tt,count,1] # INDIRECT h=1
      forecast[tt,2,2] <- bhat[1]*sum(bhat[2]^(0:3)) +
                          (bhat[2]^4)*train[N]
    }
    count <- count + 1
  }
}

# NB: L'Exercice ci-haut est fait avec une fenetre grandissante (expanding 
# window). Ceci veut simplement dire que l'echantillon utiliser pour 
# estimer les parametres des modeles croit dans le temps. Une autre facon
# de faire serait de laisser tomber une observation au debut de
# l'echantillon quand on en ajoute une a la fin. On parle alors d'une
# fenetre glissante (slidding window).

# NB: vous pourriez aussi le faire avec les fonctions R comme lm() parce que
# ces modeles s'estiment par MCO.

# =========================================================================== #
# 3. Resultats ----
# =========================================================================== #

# On va produire les figures pertinentes et les sauvegarder dans
# '30_output'

horizon <- c(1,4)
count   <- 1
for (jj in 3:4){
  # On va mettre les prevision dans un dataframe avec les vraies donnees
  df <- cbind.data.frame(gdp$Date, gdp[,jj], 
                         forecast[,count,1], forecast[,count,2])
  names(df) <- c("Date", paste("Croissance moyenne du PIB (", 
                               horizon[count], ")", sep=""),
                 "AR DIRECT", "AR INDIRECT")
  
  # On va se concentrer sur la fin de la figure
  df <- tail(df,60)
  
  # On va rearrange le dataframe dans le bon format
  molten <- melt(df, id="Date")
  
  # On ouvre une connection
  png(file=paste(paths$out, paste("POOS_", horizon[count], ".png", sep=""), 
                 sep="/"),
      width=6, height=5, unit="in", res=350)
  
  # On construit la figure
  g <- ggplot(molten) +
       geom_line(aes(x=Date, color=variable, y=value)) +
       geom_vline(xintercept = gdp$Date[start],
                  linetype=2) +
       ylab("Taux de croissance moyen") + 
       xlab("") + theme_bw() + theme(legend.position = "top",
                                     legend.title = element_blank()) +
       scale_color_manual(values=c("#000000", "#009E73","#E69F00"))
  
  # On enregistre en imprimant la figure dans le fichier
  print(g)
  
  # On ferme la connection
  dev.off()
  
  count <- count + 1
}

# NB: Evidemment, les graphiques sont un peu differents de ceux fait avec
# MATLAB parce qu'on prevoit une variable un peu differente.


# A partir d'ici, vous pouvez aussi construire les erreurs de prevision
# hors echantillon et calculer toutes les statistiques que vous voulez.

# =========================================================================== #
# 4. Exercices ----
# =========================================================================== #

# 4.1
# Refaites cet exercice, mais cette fois-ci avec un modele different. Par
# exemple, vous pourriez faire un modele du type suivant:
# gr(t) = a(h) + b(h)*gr(t-h) + d(h)*X(t-h) + e(t)

# ETAPES:
# 1. Vous allez chercher sur FRED la variable suivante:
# USREC
# Elle indique les dates de recessions selon le NBER en frequence mensuel.
#
# 2. Vous devez la convertir en frequence trimestrielle. Ca veut simplement
# dire que vous allez utiliser Q1=mars, Q2=juin, Q3=septembre, Q4=decembre.
# Le GDP comment en 1947Q1, donc vous trouvez mars 1947 dans ce que vous
# avez importer. Si il s'agit de a ligne 38 (aucun rapport), vous pouvez
# recuperer tous les mois dans un sequence avec sauts de 3 mois en
# utilisant seq(38,N,3) pour indexer les bonnes lignes ou N=dim(USREC)[1] est
# le nombre d'observations.

# 3. Une fois que vous avez les recessions en trimestriel, vous allez
# ajuster les dimensions. On laisse tomber 4 periodes parce qu'on a des
# taux de croissances moyens sur 4 trimestres. Ensuite, il faut vous
# assurez que GDP et USREC en trimestriel finissent au meme moment. Il se
# peut que USREC finisse plus tard. Si oui, laisser tomber les observations
# de trop de USREC.

# 4. Vous n'avez qu'a estimer le modele ci-haut par OLS dans le meme genre
# de boucle que j'ai codee plus haut. Vous pourriez reprendre le meme code
# a ceci pres que vous avez besoin d'une troisieme position pour la
# dimension "modele" et que, evidemment, il faut faire la bonne regression
# pour ce 3e type de modele.

# 4.2.
# Presenter les resultats de l'exercice ci-haut sous forme de figure.

# 4.3.
# Refaites l'exemple que je vous ai donne plus haut, mais cette fois-ci,
# faites-le avec une fenetre glissante. Ca veut dire que quand tt=start,
# vous commencez avec l'observation 1, quand tt=start+1, vous laissez
# tomber l'observation 1 et ainsi de suite.

# 4.4.
# Comparez les resultats en expanding et slidding windows.