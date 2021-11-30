import matplotlib.pyplot as plotter

file = open('output/separated_contigs.fa.bed')
data = file.read()
file.close()

lines = data.split('\n')

for line in lines:
	if not line:
		continue
	
	tokens = line.split()
	start = int(tokens[1])
	end = int(tokens[2])
	#label = tokens[3]

	y = 0
	
	plotter.plot([start, end], [y, y], linewidth=10)
	plotter.title('Extent of the Separated Molecules on the Draft Sequence')
	plotter.yticks([])

#plotter.show()
plotter.savefig('output/separated_molecules.png')
