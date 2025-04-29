#!/usr/bin/Rscript
print("STARTING ANALYSIS")
args = commandArgs(trailingOnly=TRUE)


#library(limma)
library(FragPipeAnalystR)
library(ggplot2)
print("Libraries loaded")

print(args[1])
print(args[2])
print(args[3])
print(args[4])
print(args[5])
print(args[6])
print(args[7])
print(args[8])
print(args[9])
#projectDir = args[1]
experiment_annotation = args[1]
p_table = args[2]
mode = args[3]
params_gene_list = unlist(strsplit(args[4], ","))
analyst_mode = args[5]
plot_mode = args[6]
go_database = args[7]
output_dir = args[8]

print(params_gene_list)
print(typeof(experiment_annotation))
print(typeof(p_table))


data <- make_se_from_files(p_table, experiment_annotation,
							type = mode, level = analyst_mode)

pdf(file=paste(args[9], "/", output_dir,"/output.pdf", sep=""), width = 10, height = 7, pointsize = 14, title = "FragPipe-Analyst Report")
par(mar=c(15, 15, 15, 35))

print(data)
print("")

print(colData(data)$condition)

if (mode == "TMT"){
	data[is.na(data)] <- 0
	imputed_data <- data
} else {
	imputed_data <- manual_impute(data)
	plot_feature_numbers(imputed_data)
}

plot_pca(imputed_data)
plot_correlation_heatmap(imputed_data)

de_data <- test_limma(imputed_data, type = "all")
contrast_txt <- capture.output(test_limma(imputed_data, type = "all"), type = "message")
de_data_rejections <- add_rejections(de_data)

print("Here is the output msg:")
print(contrast_txt)
cond <- strsplit(contrast_txt, " ")
print(cond)

print(de_data@elementMetadata@listData)
table_data <- de_data@elementMetadata@listData
df <- as.data.frame(table_data)
head(df)
write.csv(df, paste(args[9], "/",output_dir,"/output.csv", sep=""), row.names = F)

# get_column_name <- function(mode, plot_mode) {
#   if (mode == "DIA") {
#     if (plot_mode == "protein") return("ID")
#     if (plot_mode == "gene") return("Genes")
#     return("ID")
#   } else if (mode == "TMT") {
#     if (plot_mode == "protein") return("Protein.ID")
#     if (plot_mode == "gene") return("Index")
#     return("Protein.ID")
#   } else {
#     if (plot_mode == "protein") return("Protein.ID")
#     if (plot_mode == "gene") return("Gene")
#     return("Protein.ID")
#   }
# }

# col_name <- get_column_name(mode, plot_mode)
# plot_mode <- col_name
# params_gene_list <- if (col_name %in% colnames(df)) {
#   params_gene_list[params_gene_list %in% df[[col_name]]]
# } else {
#   c()
# }


if (mode != "DIA") {
	if (plot_mode == "protein") {
		plot_mode <- "ProteinID"
		params_gene_list <- params_gene_list[params_gene_list %in% df$ProteinID]
	} else if (plot_mode == "gene") {
		plot_mode <- "Gene"
		params_gene_list <- params_gene_list[params_gene_list %in% df$Gene]
	} else {
		plot_mode <- "Protein.ID"
		params_gene_list <- c()
	}
} else {
	if (plot_mode == "protein") {
		plot_mode <- "ID"
		params_gene_list <- params_gene_list[params_gene_list %in% df$ID]
	} else if (plot_mode == "gene") {
		plot_mode <- "Genes"
		params_gene_list <- params_gene_list[params_gene_list %in% df$Gene]
	} else {
		plot_mode <- "ID"
		params_gene_list <- c()
	}
}
#TODO: based on mode plot_mode column selection is different!!!

plot_cvs(de_data_rejections)

print(de_data_rejections)
print("Volcano plot")

plot_volcano(de_data_rejections, cond[[1]][3], name_col = plot_mode, add_names = T)

print(de_data_rejections$p.value)

print(plot_mode)
#TODOOOOOO
protein_list <- c("Q4KMQ2", "P15559", "A1L0T0", "A0FGR8", "A0JLT2", "O00754", "O14514")
gene_list <- c("ESYT2", "MED19", "UHRF1BP1L", "SHTN1", "SLC22A23", "MEX3A", "ILVBL")

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

or_result_up <- or_test(de_data_rejections, database = go_database, direction = "UP")
or_result_down <- or_test(de_data_rejections, database = go_database, direction = "DOWN")

print("GO enrichment analysis plots")
plot_or(or_result_up) + ggtitle("Upregulated")
plot_or(or_result_down) + ggtitle("Downregulated")

# pdf(file=paste(args[9], "/", output_dir,"/gsea_output.pdf", sep=""), width = 10, height = 10, pointsize = 11, title = "GSEA Report")
# plot_or(or_result_up) + ggtitle("Upregulated") +  theme(
#     axis.title = element_text(size = 16),      # Axis titles
#     axis.text = element_text(size = 14),       # Axis tick labels
#     legend.title = element_text(size = 14),    # Legend title
#     legend.text = element_text(size = 12))
# plot_or(or_result_down) + ggtitle("Downregulated") +  theme(
#     axis.title = element_text(size = 16),      # Axis titles
#     axis.text = element_text(size = 14),       # Axis tick labels
#     legend.title = element_text(size = 14),    # Legend title
#     legend.text = element_text(size = 12))

dev.off()

print("FragPipe-Analyst Report finished successfully.")
