make_latex <- function(content, options=NULL, file_name=NULL, rnames=NULL){
  # Author: Stephane Surprenant, UQAM
  # Creation: 19/03/2019
  #
  # Description: This function produces a LaTeX table from a dataframe content
  #              and prints the output to file_name or, if NULL, the output is
  #              printed to the console.
  #
  # INPUTS
  # content: a dataframe with row names and column names as desired to appear
  #          in the table. Must contain numeric inputs.
  # options: $title, $notes and $multiol, the last must specify the full LaTeX
  #          code for this line in the table .tex file.
  #
  # Modifications:
  # 1. Donner les noms de lignes directement.
  # ========================================================================= #
  
  if (is.null(options)){
    options <- list(title = "Title",
                    notes = "",
                    multicol = "",
                    size     = "")
  }
  if (is.null(rnames)){
    rnames <- rownames(content)
  }
  
  nc <- ncol(content) # Number of columns plus column
  nr <- nrow(content) # Number of rows  
  
  # HEAD -------------------------------------------------------------------- #
  table_head <- c("\\begin{table}[H] ",
                  "\\begin{center}  ",
                  paste("\\caption{", options$title, "} ", options$size,
                        sep=""),
                  paste("\\begin{tabular}{l", 
                        paste(rep("c", nc), collapse="")
                        ,"}", sep=""),
                  "\\toprule \\toprule ")
  
  # CORE -------------------------------------------------------------------- #
  if (options$multicol != ""){
    table_core <- c(options$multicol, 
                    paste(paste(paste("&", colnames(content)), collapse=" "),
                          "\\\\ \\midrule", collapse=" "))
  } else {
    table_core <- c(paste(paste(paste("&", colnames(content)), collapse=" "),
                        "\\\\ \\midrule", collapse=" "))
  }
  
  addition   <- array(dim=c(nr))
  for (i in 1:nr){
    if (!is.numeric(content[i,])){ # Non-numerical rows
      if (i < nr){
        addition[i] <- paste(rnames[i], 
                             paste("&", as.matrix(content[i,]), 
                                   collapse=" "), "\\\\", 
                             collapse=" ")
      } else {
        addition[i] <- paste(rnames[i], 
                             paste("&", as.matrix(content[i,]), 
                                   collapse=" "), 
                             "\\\\ \\bottomrule \\bottomrule", 
                             collapse=" ")
      }
    } else { # Numerical rows
      if (i < nr){
        addition[i] <- paste(paste(rnames[i],
                                   paste(gsub(x=paste("&",format(round(content[i,], 
                                                                       digits=2), 
                                                                 nsmall=3)), 
                                              pattern=".000", 
                                              replacement=""), collapse=" "), 
                                   collapse=""), "\\\\", collapse=" ")
      } else { # Last row is different: it needs bottom lines
        addition[i] <-paste(paste(rnames[i],
                                  paste(gsub(x=paste("&",format(round(content[i,], 
                                                                      digits=2), 
                                                                nsmall=3)), 
                                             pattern=".000", 
                                             replacement=""), collapse=" "), 
                                  collapse=""), "\\\\ \\bottomrule \\bottomrule", 
                            collapse=" ")
      }
    }
  }
  # 
  # addition   <- array(dim=c(nr))
  # for (i in 1:nr){
  #   if (!is.numeric(content[i,])){ # Non-numerical rows
  #     if (i < nr){
  #       addition[i] <- paste(rownames(content[i,]), 
  #                            paste("&", as.matrix(content[i,]), 
  #                                  collapse=" "), "\\\\", 
  #                            collapse=" ")
  #     } else {
  #       addition[i] <- paste(rownames(content[i,]), 
  #                            paste("&", as.matrix(content[i,]), 
  #                                  collapse=" "), 
  #                            "\\\\ \\bottomrule \\bottomrule", 
  #                            collapse=" ")
  #     }
  #   } else { # Numerical rows
  #     if (i < nr){
  #       addition[i] <- paste(paste(rownames(content[i,]),
  #                                  paste(gsub(x=paste("&",format(round(content[i,], 
  #                                                                      digits=2), 
  #                                                                nsmall=3)), 
  #                                             pattern=".000", 
  #                                             replacement=""), collapse=" "), 
  #                                  collapse=""), "\\\\", collapse=" ")
  #     } else { # Last row is different: it needs bottom lines
  #       addition[i] <-paste(paste(rownames(content[i,]),
  #                                 paste(gsub(x=paste("&",format(round(content[i,], 
  #                                                                     digits=2), 
  #                                                               nsmall=3)), 
  #                                            pattern=".000", 
  #                                            replacement=""), collapse=" "), 
  #                                 collapse=""), "\\\\ \\bottomrule \\bottomrule", 
  #                           collapse=" ")
  #     }
  #   }
  # }
  table_core <- c(table_core, addition)
  
  # FOOT -------------------------------------------------------------------- #
  if (options$notes != ""){
    table_foot <- c("\\end{tabular} ",
                    "\\end{center} ",
                    "\\end{table} ",
                    "\\vspace{-3em} ",
                    "\\begin{footnotesize} ",
                    "\\flushleft ",
                    options$notes,
                    "\\end{footnotesize}")
  } else {
    table_foot <- c("\\end{tabular} ",
                    "\\end{center} ",
                    "\\end{table} ")
  }
  # PRINT TABLE -------------------------------------------------------------- #
  
  if (is.null(file_name)){
    cat(c(table_head,table_core,table_foot), sep="\n")
  } else {
    connect <- file(file_name)
    writeLines(c(table_head,table_core,table_foot), con=connect, sep="\n")
    close(connect)
  }
  
}