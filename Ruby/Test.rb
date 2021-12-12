require_relative "Person"


# create first family tree
p1 = Person.new("Max", "Power", 1950, "none")
p2 = Person.new("Emily", "Power", 1974, "none")
p3 = Person.new("Lisa", "Power", 1970, "none")
p4 = Person.new("Sam", "Burton", 2000, "none")
p5 = Person.new("Jack", "Burton", 1995, "none")
p6 = Person.new("James", "Holden", 2015, "none")

p1.add_child(p2)
p1.add_child(p3)
p2.add_child(p4)
p2.add_child(p5)
p5.add_child(p6)

# create second family tree
p7 = Person.new("Linda", "Wallace", 1952, "none")
p8 = Person.new("Maggie", "Reynolds", 1972, "none")
p9 = Person.new("Naomi", "Nagata", 1992, "none")

p7.add_child(p8)
p8.add_child(p9)

# add p7 as spouse to p1
p1.add_spouse(p7.name, p7.children)


# testing the each method to print the elements of the tree
# the results should contain "Maggie" and her child "Naomi", who where in 
# the family tree of "Linda Wallace", who was later added as a spouse to "Max Power"
puts "Tree starting from #{p1.name} #{p1.surname} using each method..."
p1.each {|p| puts "#{p.name} #{p.surname} #{p.year_birth}"}
puts

puts "Tree starting from #{p7.name} #{p7.surname} using each method..."
p7.each {|p| puts "#{p.name} #{p.surname} #{p.year_birth}"}
puts

# Test searching for a name in the tree
search = "Maggie"

puts "Testing if the name \"#{search}\" can be found in the tree..."
p1.each {|p| 
	if p.name == search
		puts "\"#{search}\" found in the tree!"
		puts p
		break
	end
}
puts

# testing the sort method, the results should be ordered by birth year, even if we change the
# birthyear of the root Person
puts "Testing the sort method on the tree, with birth year of Max Power modified..."
p1.year_birth=2020
p1.sort.each {|p| puts "#{p.name} #{p.surname} #{p.year_birth}"}
puts

# testing the traverse BFS method
puts "Tree starting from #{p1.name} #{p1.surname} using BFS traverse method..."
p1.traverse_bfs
puts

# testing the number of persons
puts "The total number of persons is: #{Person.num_people}"
puts
