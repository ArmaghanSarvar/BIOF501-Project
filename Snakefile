configfile: "config.yaml"

def download_commands(store_path, download_link, zipped):
	if download_link == "":
		return ""

	if zipped:
		zipped_path = store_path + ".gz"
		command = "curl " + download_link + " --output " + zipped_path + "\n"
		command += "gunzip -c " + zipped_path + " > " + store_path + "\n"
		command += "rm " + zipped_path
		return command
	else:
		return "curl " + download_link + " --output " + store_path

download_contig_commands = download_commands(config['input_contig_path'], config['contig_download_link'], config['zipped_contig'])

download_linked_reads_commands = download_commands(config['input_linked_reads_path'], config['linked_reads_download_link'], config['zipped_linked_reads'])

rule all:
	input:
		"output/separated_molecules.png"

rule download_dataset:
	output:
		contig = config['input_contig_path'],
		linked_reads = config['input_linked_reads_path']

	shell:
		"""
		{download_contig_commands}
		{download_linked_reads_commands}
		"""

rule index_contig:
	input:
		rules.download_dataset.output.contig

	output:
		config['input_contig_path'] + ".fai"

	shell:
		"samtools faidx {input}"

rule alignments:
	input:
		contig = rules.download_dataset.output.contig,
		linked_reads = rules.download_dataset.output.linked_reads

	output:
		"data/alignments.bam"

	shell:
		"""
		bwa index {input.contig}
		bwa mem -C -t{config[threads]} {input.contig} {input.linked_reads} | samtools sort -tBX -o {output} -@{config[threads]}
		"""

rule determine_molecule_extents:
	input:
		rules.alignments.output

	output:
		"data/molecules.bed"

	shell:
		"tigmint-molecule {input} -s{config[minimum_molecule_size]} -o {output}"

rule cut_misassemblies:
	input:
		molecules = rules.determine_molecule_extents.output,
		contig = rules.download_dataset.output.contig,
		index = rules.index_contig.output

	output:
		separated_contigs = "data/separated_contigs.fa",
		separated_molecules = "data/separated_contigs.fa.bed"

	shell:
		"tigmint-cut -n{config[spanning_molecule_threshold]} -w{config[window_size]} -t{config[trim]} -p{config[threads]} {input.contig} {input.molecules} -o {output.separated_contigs}"

rule visualize:
	input:
		rules.cut_misassemblies.output.separated_molecules

	output:
		"output/separated_molecules.png"

	script:
		"visualize_separated_molecules.py"


