class Person

	include Enumerable

	# define class variable
	@@num_people = 0

	# define starndard accessors
	attr_accessor :name, :surname, :year_birth, :married_with, :children, :parent

	# define intializer for the class
	def initialize(name, surname, year_birth, married_with)
		@name = name
		@surname = surname
		@year_birth = year_birth
		@married_with = married_with
		@children = []
		@parent = nil
		@@num_people = @@num_people + 1
	end

	# returns the number of people initialized
	def self.num_people
		return @@num_people
	end

	def add_child(child)
		#add this child to the next free element of the array
		@children[children.length] = child
		
		# sort the array with bubble sort algorithm
		for i in 0..@children.length - 2
			for j in i+1..@children.length - 1
				if @children[i].year_birth > @children[j].year_birth
					temp = @children[i]
					@children[i] = @children[j]
					@children[j] = temp
				end
			end
		end

		#update this child with the reference of the parent
		child.parent=self
	end

	def add_spouse(spouse_name, children=[])
		@married_with = spouse_name

		if children != nil
			for i in 0..children.length-1
				add_child(children[i])
			end
		end
	end

	def to_s

		output = "-----------------\n"
		output += "name: #{@name} #{@surname}"

		if @parent != nil
			output += ", child of #{@parent.name} #{@parent.surname}\n"
		else
			output += "\n"
		end

		output += "year: #{@year_birth}\n"
		output += "married_with: #{@married_with}\n"
		output += "number of children: #{@children.length}\n"

		return output

	end

	def traverse_bfs

		# the firs element in the tree gets printed directly
		puts self
		# then the method calls the recursive version by passing his children as parameter
		traverse_bfs_recursive(children)

	end

	def traverse_bfs_recursive(upperlevel)

		# array to store the children of the lower level
		lowerlevel = []

		for i in 0..upperlevel.length - 1
			# print the children of the upper level
			puts upperlevel[i]
			if upperlevel[i].children.length != 0
				#if the person has children, collect them in the lowerlevel array
				for j in 0..upperlevel[i].children.length-1
					lowerlevel.push(upperlevel[i].children[j])
				end
			end
		end

		# if there are no children in the lower level return, otherwise
		# recursively call this method with the lowerlevel array as parameter
		if lowerlevel.length == 0
			return
		else
			traverse_bfs_recursive(lowerlevel)
		end

	end

	def each(&block)

		block.call self
		each_recursive(children, &block)

	end


	def each_recursive(upperlevel, &block)

		# array to store the children of the lower level
		lowerlevel = []

		for i in 0..upperlevel.length - 1
			# call the block function on the childrens of the upper level
			block.call upperlevel[i]
			if upperlevel[i].children.length != 0
				#if the person has children, collect them in the lowerlevel array
				for j in 0..upperlevel[i].children.length-1
					lowerlevel.push(upperlevel[i].children[j])
				end
			end
		end

		# if there are no childrens in the lower level return, otherwise
		# recursively call this method with the lowerlevel array as parameter
		if lowerlevel.length == 0
			return
		else
			each_recursive(lowerlevel, &block)
		end

	end

	# define "spaceship" operator
	def <=>(t)
		return -1 if self.year_birth < t.year_birth
		return 1 if self.year_birth > t.year_birth
		return 0 if self.year_birth == t.year_birth
	end

end