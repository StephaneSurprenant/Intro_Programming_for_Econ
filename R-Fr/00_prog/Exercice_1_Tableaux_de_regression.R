#
# Auteur: Stephane Surprenant, UQAM
# Creation: 05/08/2019
#
# Description: Ce script vous invite a construire des tableaux de resultats
# typiques en economie (surtout en microeconometrie). Je vous donne un
# exemple de comment le faire. Ensuite, je vous demande de le faire pour un
# autre cas avec les memes donnees.
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

# NB: Si vous avez une erreure, vous pouvez installer les packages comme suit:
# install.packages("nom_du_package")
# Vous pourriez aussi automatiser la procedure, mais je voulais garder le code
# simple.

# NB:, si jamais vous voulez des versions HC ou HAC des ecarts-types:
# library(lmtest)   # Tests
# library(sandwich) # Ecarts-types robustes
# library(Newey)    # Ecarts-types Newey-West

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
data <- read.csv(paste(paths$dat, "Labor_market_sim.csv", sep="/"))
data <- data[,-7]

# Pour faire les tableaux en francais:
names(data) <- c("Age", "Experience", "Salaire", "Sexe", 
                 "Diplome post-secondaire", "Quebec")

# =========================================================================== #
# 2. Faire les regressions ----
# =========================================================================== #
  
# On va faire 4 regressions pour explorer l'effet du diplome sur les
# salaires dans nos donnees simulees. Voici les 4 regressions:
# salaire(i) = b0 + b1*dip + e(i)
# salaire(i) = b0 + b1*dip + b2*sexe + b3*dip*sexe + e(i)
# salaire(i) = b0 + b1*dip + b2*sexe + b3*dip*sexe + b4*age + e(i)
# salaire(i) = b0 + b1*dip + b2*sexe + b3*dip*sexe +
#              b4*age^2 + b5*Qc + e(i)

# On veut mettre les resultats dans un tableau. L'idee est d'avoir une
# regression par colonne. Les lignes vont correspondres aux b0 a b5, en
# plus de leurs ecarts-types. Ensuite, on veut avoir le nombre
# d'observations et le R2 ajuste.

# D'abord, on veut garder les resultats, alors nous allons creer un dataframe
# dans lequel les recuperer.
regression_table <- array(NA, dim=c(6*2+2,4)) %>% as.data.frame()
N                <- dim(data)[1]
regression_table[13,] <- N


# Ajout des noms de lignes et de colonnes
rownames(regression_table) <- c("Constante", "sd(cst)", 
                                "Diplome", "sd(D)", 
                                "Sexe", "sd(S)",  
                                "DipxSexe", "sd(SxD)",  
                                "Age/age2", "sd(A/A2)",  
                                "Qc", "sd(Qc)",  
                                "Nobs","R2a")
names(regression_table)    <- paste("MCO (", 1:4, ")", sep="")

# Votre tableau a l'air de ceci:
print(regression_table)

# Maintenant, il faut estimer nos regressions. On pourrait faire encore comme
# dans MATLAB et ecrire une fonction, mais on va utiliser les fonctions de
# bases de R pour que vous puissiez les voir elles aussi. La fonction lm()
# estime un modele lineaire par MCO. E.g.:

formula <- as.formula("Salaire ~.") # Regression sur tout le rest ~.
fit     <- lm(formula, data)

# On peut voir ce qui se passe avec la commande summary(). L'objet fit est
# particulier et comprend des attributs qui font que summary() nous renvoit un
# tableau relativement complet. Notez que le contenu peut etre assigne:
a <- summary(fit)
print(a)
# Toutes les valeurs visibles sont accessibles avec a$nom. Par exemple:
print(a$r.squared)
# donne le R2. Il y a aussi le R2 ajustee.

# Donc, une facon de faire est de creer une liste de formule et remplir
# notre tableau dans une boucle.
formulas      <- list()
formulas[[1]] <- as.formula("Salaire ~ `Diplome post-secondaire`")
formulas[[2]] <- as.formula(paste("Salaire ~ `Diplome post-secondaire`",
                                  "Sexe",
                                  "I(`Diplome post-secondaire`*Sexe)", 
                                  sep=" + "))
formulas[[3]] <- as.formula(paste("Salaire ~ `Diplome post-secondaire`",
                                  "Sexe",
                                  "I(`Diplome post-secondaire`*Sexe)", 
                                  "Age", sep=" + "))
formulas[[4]] <- as.formula(paste("Salaire ~ `Diplome post-secondaire`",
                                  "Sexe",
                                  "I(`Diplome post-secondaire`*Sexe)", 
                                  "I(Age^2)","Quebec", sep=" + "))

# NB: Regardez comment on peut profiter de paste() pour coller des chaines de
# caracteres.

# Nous allons mettre de cote les p-values aussi pour pouvoir afficher les
# resultats significatifs. Les dimensions sont maximum de variables x nombre
# de regressions
pvalues <- array(NA, dim=c(5+1,4)) 

for (jj in 1:4){
  # Estimation et calculs des statistiques recherchees
  fit <- lm(formulas[[jj]], data)
  fit <- summary(fit)

  K   <- dim(fit$coefficients)[1]
  
  # Remplissons le tableau!
  # Estimes
  regression_table[seq(from=1,to=K*2,by=2),jj] <- fit$coefficients[,1]
  # Ecarts-types
  regression_table[seq(from=2,to=K*2,by=2),jj] <- fit$coefficients[,2]
  # R2 ajuste
  regression_table[14,jj] <- fit$adj.r.squared
  # Pvalues
  pvalues[1:K,jj]         <- fit$coefficients[,4]
}

# =========================================================================== #
# 3. Faire le tableau ----
# =========================================================================== #

# On doit construire une matrice entierement constituee de chaines de
# de caracteres pour pouvoir introduire les parantheses. On doit aussi ajouter
# les $^{***}$ a la main parce que la fonction n'est pas aussi complete que sur
# MATLAB.

symbols <- c("","$^{*}$", "$^{**}$", "$^{***}$")

X           <- array("", dim=dim(regression_table))
for (jj in 1:dim(X)[2]){
  # Coefficients: aucune parantheses
  count <- 1
  for (ii in seq(from=1,to=12,by=2)){
    # On met une condition pour remplacer les NAs dans le tableau
    if (is.na(regression_table[ii,jj])){
      X[ii,jj] <- "-"
    } else {
      index    <- (pvalues[count,jj] <= 0.1)  +
                  (pvalues[count,jj] <= 0.05) +
                  (pvalues[count,jj] <= 0.01) +
                  1
      X[ii,jj] <- paste(as.character(regression_table[ii,jj]),
                        symbols[index], sep="")
      count <- count + 1
    }
    
  }
  # Ecarts-types: entre parantheses
  for (ii in seq(from=2,to=12,by=2)){
    if (is.na(regression_table[ii,jj])){
      X[ii,jj] <- "-"
    } else {
      X[ii,jj] <- paste("(", as.character(regression_table[ii,jj]), ")", 
                        sep="")
    }
  }
  # Ensuite, Nobs et R2 tels quels
  X[13:14,jj] <- regression_table[13:14,jj]
}
colnames(X) <- names(regression_table)
rownames(X) <- rownames(regression_table)

# NB: On ajoute 1 dans index parce que 1 correspond a la position d'un ajout
# null dans le tableau. Comme dans R, "vrai" vaut 1, donc on peut les
# additionner.

# On a aussi besoin d'options pour completer le tableau! Ici, les options se
# trouvent dans une liste avec les entrees "title", "notes", "multicol" et
# "size".

options <- list(title = "Effet du diplome sur le salaire",
                notes = paste("La variable dependante est le salaire.",  
                " La regression (3) inclus l'Age, alors que (4)",  
                " inclut l'Age au carre. Le diplome est un diplome",  
                " post-secondaire. Les femmes correspondent au cas",  
                " sexe = 0 et les ontariens au cas Qc = 0.", sep=""),
                multicol = "",
                size = "")

fname  <- paste(paths$out, "Tableau_sur_R.tex", sep="/")

# Et on fait le tableau:
make_latex(content=X, options=options, file_name = fname, rnames=rownames(X))


# =========================================================================== #
# 4. EXERCICE 1.1: faire un nouveau tableau ----
# =========================================================================== #

# Vous devez par vous-meme effectuer 3 regressions et construire un tableau
# similaire au tableau ci-haut. Je vous donne les equations de regressions,
# mais je ne vous dis pas comment faire. Par contre, tout doit y etre.

# Indice sur le format du tableau: le tableau ci-haut aurait aussi pu etre
# fait avec 2 lignes de plus. C'est-a-dire qu'on aurait pu mettre age et
# age^2 separemment. C'est d'ailleurs la facon normale de proceder.

# Regressions:
# salaire(i) = b0 + b1*sexe + e(i)
# salaire(i) = b0 + b1*sexe + b2*sexe*diplome + e(i)
# salaire(i) = b0 + b1*sexe + b2*sexe*age + b3*diplome + e(i)

# Amusez-vous!
  
# =========================================================================== #
# 5. EXERCICE 1.2: faire des figures ----
# =========================================================================== #
  
# Dans le script 'Introduction', il y a des exemples de figures. Pour cet
# exercice, vous allez effectuer une regression de votre choix et recuperer
# les valeurs predites (yhat = X*bhat). Vous pouvez les calculer a la main ou
# encore utiliser lm(). Pour savoir comment utiliser lm(), entrez ceci:
?lm

# Vous devez sortir un nuage de points, cette-fois. Ceci suppose que vous
# trouviez par vous-meme comment utiliser la fonction geom_points() avec
# ggplot.

# Vous avez 2 options pour le faire:

# 1. Vous faites un dataframe avec les variables suivantes: Salaire, Age et
# le salaire prevu par MCO. Vous utilisez 2 fois geom_points(): e.g.,
# ggplot(dataframe)+geom_points(aes(x=`Age`, y=Salaire))+
# geom_point(aes(x=`Age`, y=`Salaire prevu`))
# ATTENTION: les noms doivent correspondent aux noms dans le dataframe

# 2. Vous construisez ce meme dataframe, mais vous utilisez la fonction
# melt() de reshape2. ATTENTION: vous devez importer la bibliotheque reshape2
# avant de vous servir de melt(). Il y a un exemple dans le script nomme
# "Introduction.R" dans R/00_prog.

# Evidemment, si vous aviez beaucoup de variables, la 2e facon est plus rapide