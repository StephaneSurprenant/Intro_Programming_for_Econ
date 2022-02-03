filtreHP <- function(y,lambda=1600){
  #
  # Auteur: Stephane Surprenant, UQAM
  # Creation: 04/08/2019
  #
  # Description: Filtre Hodrick-Prescott base sur le code MATLAB de Ivailo
  # Izvorski.
  #
  # INPUTS
  # lambda: parametre de lissage
  # y     : serie originale
  #
  # OUTSPUTS
  # results: $filtered: series filtree
  #          $res     : composante cyclique
  #
  # NB: Voyez comme c'est facile dans R d'introduire des valeurs par defaut.
  # ========================================================================= #
  
  # Ajustement des formats
  y <- as.matrix(y)
  if (dim(y)[1] < dim(y)[2]) {
    y <- t(y) # On met le temps dans le sens des lignes
  }
  
  # Calculs
  N <- dim(y)[1]
  
  a <- 6*lambda+1
  b <- (-4)*lambda
  c <- lambda
  
  d <- array(c(c,b,a), dim=c(1,3))
  d <- array(1, dim=c(N,1))%*%d
  
  # Make diagonal matrix
  m                            <- diag(d[,3])
  m[abs(row(m) - col(m)) == 1] <- d[1,2]
  m[abs(row(m) - col(m)) == 2] <- d[1,1]
  
  # Modify top and bottom corners
  m[1,1] <- 1+lambda        
  m[1,2] <- -2*lambda 
  m[2,1] <- -2*lambda       
  m[2,2] <- 5*lambda+1 
  m[N-1,N-1] <- 5*lambda+1 
  m[N-1,N]   <- -2*lambda 
  m[N,N-1]   <- -2*lambda     
  m[N,N]     <- 1+lambda 
  
  # Compute filtered series
  results     <- as.data.frame(solve(m)%*%y)
  results$res <- y - results[,1]
  names(results)[1] <- 'filtered'
  
  return(results)
}