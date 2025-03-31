#!/usr/bin/Rscript
print("STARTING ANALYSIS")
args = commandArgs(trailingOnly=TRUE)


#library(limma)
library(FragPipeAnalystR)
print("Libraries loaded")

print(args[1])
print(args[2])
print(args[3])
print(args[5])
print(args[6])
projectDir = args[1]
experiment_annotation = args[2]
protein_table = args[3]
mode = args[4]
params_gene_list = unlist(strsplit(args[5], ","))
plot_mode = args[6]

print(params_gene_list)
print(typeof(experiment_annotation))
print(typeof(protein_table))


data <- make_se_from_files(protein_table, experiment_annotation,
							type = mode, level = "protein")

pdf(file=paste(args[8], "/", args[7],"/output.pdf", sep=""), width = 10, height = 7, pointsize = 14, title = "FragPipe-Analyst Report")
par(mar=c(15, 15, 15, 35))

print(data)
print("")

print(colData(data)$condition)

imputed_data <- manual_impute(data)

plot_feature_numbers(imputed_data)
plot_pca(imputed_data)
plot_correlation_heatmap(imputed_data)

de_data <- test_limma(imputed_data, type = "all")
contrast_txt <- capture.output(test_limma(imputed_data, type = "all"), type = "message")
de_data_rejections <- add_rejections(de_data)

print("Here is the output msg:")
print(contrast_txt)
cond <- strsplit(contrast_txt, " ")
print(cond)

if (plot_mode == "protein") {
  plot_mode <- "Protein.ID"
} else if (plot_mode == "gene") {
  plot_mode <- "Gene"
} else {
  plot_mode <- "Protein.ID"
}

plot_cvs(de_data_rejections)

plot_volcano(de_data_rejections, cond[[1]][3], name_col = plot_mode)

print(de_data_rejections$p.value)

print(plot_mode)
#TODOOOOOO
protein_list <- c("Q4KMQ2", "P15559", "A1L0T0", "A0FGR8", "A0JLT2", "O00754", "O14514")
gene_list <- c("ESYT2", "MED19", "UHRF1BP1L", "SHTN1", "SLC22A23", "MEX3A", "ILVBL")

params_gene_list <- c()

if (length(params_gene_list) != 0) {
	seq_indices <- seq(1, length(params_gene_list)+1, by = 6)
	lapply(seq_indices, function(i) {
		print(plot_mode)	
		if (plot_mode == "Gene") {
			print("if part")
			print(params_gene_list)
			plot_feature(de_data_rejections, params_gene_list[i:min(i+5, length(params_gene_list))], index = "name")
		} else {
			print("else part")
			plot_feature(de_data_rejections, params_gene_list[i:min(i+5, length(params_gene_list))])
		}
	})
}

print(de_data@elementMetadata@listData)
table_data <- de_data@elementMetadata@listData
df <- as.data.frame(table_data)
head(df)
write.csv(df, paste(args[8], "/",args[7],"/output.csv", sep=""), row.names = F)

dev.off()


print("Hello container")
