/***
* Name: RobotsCognitifs
* Author: babacar
* Description: 
* Tags: Tag1, Tag2, TagN
***/

model CognitiveRobots

global
{
	file robots_positions_file <- csv_file("../includes/5_5_5_robots_positions.csv", ";");
	matrix robots_positions_data <- matrix(robots_positions_file);
	int current_robots_positions_data_counting <- 1;
	file matters_positions_file <- csv_file("../includes/5_5_5_matters_positions.csv", ";");
	matrix matters_positions_data <- matrix(matters_positions_file);
	int current_matters_positions_data_counting <- 1;
	string robot_type <- "cognitive";
	int number_of_bases <- 1;
	int number_of_robots <- robots_positions_data.rows;
	int number_of_matters <- matters_positions_data.rows;
	int number_of_remaining_matters <- number_of_matters;
	int number_of_dropped_matters_in_base <- 0;
	int base_radius <- 10;
	float moving_speed <- 0.05;
	float moving_amplitude <- 1.0;
	float interception_distance <- 1.0;
	float drop_in_base_distance <- 0.9 * base_radius;
	rgb pick_color <- # green;
	rgb default_robot_color <- # red;
	rgb default_matter_color <- # yellow;
	point default_base_location <- point(75, 75);
	
	init
	{
		do create_gui_elements;
	}
	
	action create_gui_elements
	{
		create base number: 1;
		create robots number: number_of_robots;
		create matters number: number_of_matters;
	}
	
	reflex stop_simulation when: number_of_dropped_matters_in_base = number_of_matters
	{
		do pause;
		save[robot_type, number_of_bases, number_of_robots, number_of_matters, number_of_dropped_matters_in_base, cycle] to: "../outputs/cognitive_robots_number_of_cycles.csv" type: "csv" rewrite: false;
		write "Nombre de cycles d'éxecution: " + cycle;
	}
}

species base
{
	init
	{
		location <- default_base_location;
	}

	aspect default
	{
		draw circle(10) color: # blue;
	}
}

species robots skills: [moving]
{
	matters target <- nil;
	bool has_picked_matter <- false;
	point base_location <- nil;
	rgb color <- default_robot_color;
	
	init
	{
		speed <- moving_speed;
		int x <- robots_positions_data[0, current_robots_positions_data_counting];
		int y <- robots_positions_data[1, current_robots_positions_data_counting];
		current_robots_positions_data_counting <- current_robots_positions_data_counting + 1;
		location <- point(x, y);
	}
	
	reflex move
	{
		do wander amplitude: moving_amplitude;
	}
	
	reflex update_base_location
	{
		ask base at_distance drop_in_base_distance
		{
			myself.base_location <- location;
		}
	}
	
	reflex pick_matter when: !has_picked_matter
	{
		ask matters at_distance interception_distance
		{
			if (!self.is_in_base)
			{
				myself.target <- self;
				myself.target.is_picked_up <- true;
				myself.has_picked_matter <- true;
				myself.color <- pick_color;
			}
		}
	}
	
	reflex drop_matter_in_base when: has_picked_matter
	{
		if(base_location != nil)
		{
			do goto target: base_location speed: moving_speed;
		}
		else
		{
			ask robots
			{
				if (self.base_location != nil)
				{
					myself.base_location <- self.base_location;
					do goto target: myself.base_location speed: moving_speed;
				}
			}
		}
		ask base at_distance drop_in_base_distance
		{
			myself.color <- default_robot_color;
			myself.has_picked_matter <- false;
			myself.target.location <- myself.location;
			myself.target.is_picked_up <- false;
			myself.target.is_in_base <- true;
			if (myself.base_location = nil)
			{
				myself.base_location <- location;
			}
		}
	}
	aspect default
	{
		draw triangle(1) color: color;
	}
}

species matters skills: [moving]
{
	robots target <- nil;
	bool is_picked_up <- false;
	bool is_in_base <- false;
	bool decrement_number_of_dropped_matters_in_base <- true;
	float size <- 1.0;
	rgb color <- default_matter_color;
	
	init
	{
		int x <- matters_positions_data[0, current_matters_positions_data_counting];
		int y <- matters_positions_data[1, current_matters_positions_data_counting];
		current_matters_positions_data_counting <- current_matters_positions_data_counting + 1;
		location <- point(x, y);
	}

	reflex update_picked_matter when: is_picked_up = true
	{
		size <- 0.5;
		color <- pick_color;
	}
	
	reflex update_when_matter_is_dropped_in_base when: is_in_base = true
	{
		if (decrement_number_of_dropped_matters_in_base = true)
		{
			color <- default_matter_color;
			number_of_dropped_matters_in_base <- number_of_dropped_matters_in_base + 1;
			decrement_number_of_dropped_matters_in_base <- false;
			write "number_of_dropped_matters_in_base : " + number_of_dropped_matters_in_base;
		}
	}

	aspect default
	{
		draw circle(size) color: color;
		if (target != nil) {
			draw polyline([self.location,target.location]) color: # black;
		}
	}

}

experiment my_experiment type:gui
{
	parameter "Number of remaining" var: number_of_remaining_matters;
	parameter "Number of dropped matters in base" var: number_of_dropped_matters_in_base;
	parameter "Moving speed "var: moving_speed;
	parameter "Moving amplitude "var: moving_amplitude;
	parameter "Interception distance" var: interception_distance;
	parameter "Drop in base distance" var: drop_in_base_distance;
	parameter "Pick color "var: pick_color;
	parameter "Robots positions data "var: robots_positions_data;
	parameter "Matters positions data "var: matters_positions_data;
	output
	{
		display myDisplay
		{
			graphics "layer"
			{
				draw square(100) color: # lightgrey;
			}
			species base aspect:default;
			species robots aspect:default;
			species matters aspect:default;
		}
		display chart autosave: true refresh: every(100)
		{
			chart "Nombre de cycles" type: series
			{
				data "susceptible" value: number_of_dropped_matters_in_base color: #green;
			}
		}
	}
}