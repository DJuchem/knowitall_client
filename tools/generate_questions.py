import json
import requests
import concurrent.futures

# --- 1. THE DATASET ---
landmarks = [
    ("Easy", "What famous landmark is this?", "Eiffel Tower", ["Blackpool Tower", "Tokyo Tower", "CN Tower"], "Eiffel Tower"),
    ("Easy", "Where is this located?", "Rome", ["Athens", "Cairo", "Istanbul"], "Colosseum"),
    ("Medium", "Identify this structure.", "Sydney Opera House", ["Lotus Temple", "Burj Al Arab", "Guggenheim Museum"], "Sydney Opera House"),
    ("Medium", "What ancient site is this?", "Machu Picchu", ["Chichen Itza", "Petra", "Tikal"], "Machu Picchu"),
    ("Easy", "Name this monument.", "Taj Mahal", ["Humayun's Tomb", "The Red Fort", "Lotus Temple"], "Taj Mahal"),
    ("Hard", "Where can you find this?", "Dubai", ["Riyadh", "Doha", "Kuwait City"], "Burj Khalifa"),
    ("Medium", "Identify this clock tower.", "Big Ben", ["Spasskaya Tower", "Zytglogge", "Old Joe"], "Big Ben"),
    ("Hard", "What is this bridge?", "Golden Gate Bridge", ["Brooklyn Bridge", "Tower Bridge", "Sydney Harbour Bridge"], "Golden Gate Bridge"),
    ("Medium", "Name this statue.", "Statue of Liberty", ["Colossus of Rhodes", "Mother Russia", "Christ the Redeemer"], "Statue of Liberty"),
    ("Hard", "This formation is known as?", "Stonehenge", ["Avebury", "Carnac Stones", "Callanish Stones"], "Stonehenge"),
    ("Easy", "What is this iconic wall?", "Great Wall of China", ["Hadrian's Wall", "Berlin Wall", "Western Wall"], "Great Wall of China"),
    ("Medium", "Identify this mountain.", "Mount Fuji", ["Mount Everest", "Kilimanjaro", "Mount Rainier"], "Mount Fuji"),
    ("Medium", "Where is this cathedral?", "Moscow", ["St. Petersburg", "Kiev", "Warsaw"], "Saint Basil's Cathedral"),
    ("Easy", "What is this ancient structure?", "Pyramids of Giza", ["Nubian Pyramids", "Mayan Pyramids", "Ziggurat of Ur"], "Giza Pyramid Complex"),
    ("Hard", "Identify this temple complex.", "Angkor Wat", ["Borobudur", "Prambanan", "Bagan"], "Angkor Wat"),
    ("Medium", "This landmark is in which city?", "Berlin", ["Munich", "Vienna", "Hamburg"], "Brandenburg Gate"),
    ("Hard", "Name this rock formation.", "Uluru", ["Zion", "Grand Canyon", "Table Mountain"], "Uluru"),
    ("Medium", "What is this statue called?", "Christ the Redeemer", ["Angel of the North", "The Motherland Calls", "Spring Temple Buddha"], "Christ the Redeemer (statue)"),
    ("Easy", "Identify this sign.", "Hollywood Sign", ["Las Vegas Sign", "Route 66", "Broadway"], "Hollywood Sign"),
    ("Hard", "Where is this castle?", "Germany", ["Austria", "Switzerland", "France"], "Neuschwanstein Castle"),
    ("Medium", "What is this leaning tower?", "Leaning Tower of Pisa", ["Tower of Bologna", "Galata Tower", "Tower of London"], "Leaning Tower of Pisa"),
    ("Medium", "Identify this palace.", "Buckingham Palace", ["Windsor Castle", "Kensington Palace", "Hampton Court"], "Buckingham Palace"),
    ("Hard", "Where is this ruin located?", "Jordan", ["Egypt", "Israel", "Turkey"], "Al-Khazneh"),
    ("Easy", "What is this bridge?", "Tower Bridge", ["London Bridge", "Millennium Bridge", "Westminster Bridge"], "Tower Bridge"),
    ("Medium", "Identify this waterfall.", "Niagara Falls", ["Victoria Falls", "Iguazu Falls", "Angel Falls"], "Niagara Falls"),
    ("Hard", "This church is in which city?", "Barcelona", ["Madrid", "Seville", "Valencia"], "Sagrada Família"),
    ("Medium", "Name this mountain range.", "Himalayas", ["Andes", "Alps", "Rockies"], "Himalayas"),
    ("Easy", "What is this US monument?", "Mount Rushmore", ["Crazy Horse", "Lincoln Memorial", "Stone Mountain"], "Mount Rushmore"),
    ("Hard", "Identify this fortress.", "Alhambra", ["Alcazar", "Topkapi Palace", "Red Fort"], "Alhambra"),
    ("Medium", "Where is this canal?", "Venice", ["Amsterdam", "Bruges", "Suzhou"], "Grand Canal (Venice)"),
    ("Easy", "What tower is this?", "Space Needle", ["CN Tower", "Sky Tower", "Stratosphere"], "Space Needle"),
    ("Hard", "Identify this white temple.", "Wat Rong Khun", ["Grand Palace", "Wat Arun", "Angkor Wat"], "Wat Rong Khun"),
    ("Medium", "What is this ancient circle?", "The Pantheon", ["Parthenon", "Colosseum", "Forum"], "Pantheon, Rome"),
    ("Hard", "Where is the Blue Mosque?", "Istanbul", ["Mecca", "Dubai", "Cairo"], "Sultan Ahmed Mosque"),
    ("Easy", "Identify this skyscraper.", "Empire State Building", ["Chrysler Building", "Sears Tower", "Flatiron Building"], "Empire State Building"),
    ("Medium", "What is this canyon?", "Grand Canyon", ["Antelope Canyon", "Bryce Canyon", "Zion Canyon"], "Grand Canyon"),
    ("Hard", "Name this volcanic island.", "Santorini", ["Mykonos", "Capri", "Ibiza"], "Santorini"),
    ("Medium", "Identify this museum.", "The Louvre", ["Musee d'Orsay", "British Museum", "The Met"], "Louvre Pyramid"),
    ("Easy", "What is this arch?", "Arc de Triomphe", ["Marble Arch", "Gateway Arch", "Brandenburg Gate"], "Arc de Triomphe"),
    ("Hard", "Where is this pyramid?", "Mexico", ["Egypt", "Peru", "Guatemala"], "El Castillo, Chichen Itza"),
    ("Medium", "Identify this dam.", "Hoover Dam", ["Three Gorges Dam", "Aswan Dam", "Glen Canyon Dam"], "Hoover Dam"),
    ("Hard", "What is this golden temple?", "Harmandir Sahib", ["Wat Phra Kaew", "Shwedagon Pagoda", "Lotus Temple"], "Golden Temple"),
    ("Medium", "Name this twin tower.", "Petronas Towers", ["Willis Tower", "Taipei 101", "Shanghai Tower"], "Petronas Towers"),
    ("Easy", "Where is this square?", "New York City", ["London", "Tokyo", "Toronto"], "Times Square"),
    ("Hard", "Identify this monastery.", "Meteora", ["Mont Saint-Michel", "Tiger's Nest", "Sumela Monastery"], "Meteora"),
    ("Medium", "What is this ancient city?", "Acropolis", ["Delphi", "Olympia", "Knossos"], "Acropolis of Athens"),
    ("Hard", "Name this colorful mountain.", "Vinicunca", ["Zhangye Danxia", "Landmannalaugar", "Painted Hills"], "Vinicunca"),
    ("Medium", "Identify this opera house.", "Vienna State Opera", ["La Scala", "Metropolitan Opera", "Royal Opera House"], "Vienna State Opera"),
    ("Easy", "What is this tower?", "Tokyo Tower", ["Eiffel Tower", "Canton Tower", "Seoul Tower"], "Tokyo Tower"),
    ("Hard", "Where is this library?", "Dublin", ["Oxford", "Cambridge", "London"], "Library of Trinity College Dublin")
]

art = [
    ("Easy", "Who painted this?", "Leonardo da Vinci", ["Raphael", "Michelangelo", "Donatello"], "Mona Lisa"),
    ("Medium", "Name this painting.", "The Starry Night", ["Night Watch", "Cafe Terrace at Night", "Sunflowers"], "The Starry Night"),
    ("Medium", "Who is the artist?", "Edvard Munch", ["Gustav Klimt", "Egon Schiele", "Vincent van Gogh"], "The Scream"),
    ("Hard", "What is the title of this work?", "The Birth of Venus", ["Primavera", "Venus of Urbino", "The Three Graces"], "The Birth of Venus"),
    ("Medium", "This fresco is located where?", "Sistine Chapel", ["Louvre Museum", "Uffizi Gallery", "St. Peter's Basilica"], "The Creation of Adam"),
    ("Hard", "Who painted 'The Girl with a Pearl Earring'?", "Johannes Vermeer", ["Rembrandt", "Frans Hals", "Jan Steen"], "Girl with a Pearl Earring"),
    ("Hard", "Identify this style of art.", "Abstract", ["Impressionism", "Realism", "Baroque"], "Composition VIII"),
    ("Medium", "This wave is by which artist?", "Hokusai", ["Hiroshige", "Utamaro", "Kuniyoshi"], "The Great Wave off Kanagawa"),
    ("Medium", "Name this surrealist work.", "The Persistence of Memory", ["The Elephants", "The Son of Man", "Golconda"], "The Persistence of Memory"),
    ("Hard", "Who painted 'American Gothic'?", "Grant Wood", ["Edward Hopper", "Andrew Wyeth", "Norman Rockwell"], "American Gothic"),
    ("Easy", "Who painted the ceiling of the Sistine Chapel?", "Michelangelo", ["Da Vinci", "Raphael", "Botticelli"], "Sistine Chapel ceiling"),
    ("Medium", "Name this sculpture.", "David", ["The Thinker", "Discobolus", "Venus de Milo"], "David (Michelangelo)"),
    ("Medium", "Who created 'The Thinker'?", "Auguste Rodin", ["Michelangelo", "Bernini", "Donatello"], "The Thinker"),
    ("Hard", "Identify this street art.", "Banksy", ["Shepard Fairey", "Keith Haring", "Basquiat"], "Girl with Balloon"),
    ("Medium", "Who painted 'Water Lilies'?", "Claude Monet", ["Manet", "Renoir", "Degas"], "Water Lilies (Monet series)"),
    ("Hard", "Name this pointillist painting.", "A Sunday Afternoon on the Island of La Grande Jatte", ["The Starry Night", "The Scream", "Impression, Sunrise"], "A Sunday Afternoon on the Island of La Grande Jatte"),
    ("Medium", "Who is the artist of 'The Kiss'?", "Gustav Klimt", ["Egon Schiele", "Oskar Kokoschka", "Marc Chagall"], "The Kiss (Klimt)"),
    ("Easy", "What style is this?", "Cubism", ["Surrealism", "Impressionism", "Realism"], "The Weeping Woman"),
    ("Medium", "Who painted 'Guernica'?", "Pablo Picasso", ["Salvador Dali", "Joan Miro", "Frida Kahlo"], "Guernica (Picasso)"),
    ("Hard", "Identify this Frida Kahlo painting.", "Self-Portrait", ["The Two Fridas", "The Broken Column", "Diego and I"], "Self-Portrait with Thorn Necklace and Hummingbird"),
    ("Medium", "Who painted 'The Night Watch'?", "Rembrandt", ["Vermeer", "Rubens", "Van Dyck"], "The Night Watch"),
    ("Easy", "Name this soup can art.", "Andy Warhol", ["Roy Lichtenstein", "Jasper Johns", "Jackson Pollock"], "Campbell's Soup Cans"),
    ("Medium", "Who painted 'The Last Supper'?", "Leonardo da Vinci", ["Michelangelo", "Raphael", "Tintoretto"], "The Last Supper (Leonardo)"),
    ("Hard", "What movement is this?", "Impressionism", ["Expressionism", "Surrealism", "Romanticism"], "Impression, Sunrise"),
    ("Medium", "Identify this melting clock painting.", "The Persistence of Memory", ["Time Transfixed", "The Treachery of Images", "Golconda"], "The Persistence of Memory"),
    ("Easy", "Who painted this ballerina?", "Edgar Degas", ["Monet", "Manet", "Renoir"], "The Star (Degas)"),
    ("Hard", "Name this Gothic painting.", "American Gothic", ["Whistler's Mother", "The Son of Man", "Nighthawks"], "American Gothic"),
    ("Medium", "Who is the artist?", "Edward Hopper", ["Grant Wood", "Norman Rockwell", "Andrew Wyeth"], "Nighthawks"),
    ("Hard", "Identify this artist.", "Keith Haring", ["Basquiat", "Banksy", "Warhol"], "Keith Haring"),
    ("Medium", "What is this ancient sculpture?", "Venus de Milo", ["Winged Victory", "Laocoon", "David"], "Venus de Milo"),
    ("Easy", "Who painted sunflowers?", "Vincent van Gogh", ["Monet", "Gauguin", "Cezanne"], "Sunflowers (Van Gogh series)"),
    ("Hard", "Identify this Renaissance artist.", "Raphael", ["Michelangelo", "Da Vinci", "Titian"], "Raphael"),
    ("Medium", "Name this pop art.", "Roy Lichtenstein", ["Andy Warhol", "Keith Haring", "Jasper Johns"], "Whaam!"),
    ("Medium", "Who painted 'The School of Athens'?", "Raphael", ["Michelangelo", "Da Vinci", "Botticelli"], "The School of Athens"),
    ("Hard", "Identify this sculpture.", "Winged Victory of Samothrace", ["Venus de Milo", "The Thinker", "David"], "Winged Victory of Samothrace"),
    ("Easy", "What art tool is this?", "Palette Knife", ["Brush", "Easel", "Canvas"], "Palette knife"),
    ("Medium", "Who painted 'Liberty Leading the People'?", "Eugene Delacroix", ["Gericault", "David", "Ingres"], "Liberty Leading the People"),
    ("Hard", "Name this painting.", "The Garden of Earthly Delights", ["The Last Judgment", "The Haywain", "The Tower of Babel"], "The Garden of Earthly Delights"),
    ("Medium", "Who is the artist?", "Jackson Pollock", ["Mark Rothko", "Willem de Kooning", "Franz Kline"], "Jackson Pollock"),
    ("Easy", "What is this object?", "Easel", ["Canvas", "Palette", "Brush"], "Easel"),
    ("Hard", "Identify this artist.", "Jean-Michel Basquiat", ["Keith Haring", "Andy Warhol", "Banksy"], "Jean-Michel Basquiat"),
    ("Medium", "Who painted 'The Wanderer above the Sea of Fog'?", "Caspar David Friedrich", ["Turner", "Constable", "Blake"], "Wanderer above the Sea of Fog"),
    ("Medium", "Name this portrait.", "Whistler's Mother", ["American Gothic", "Mona Lisa", "The Girl with a Pearl Earring"], "Whistler's Mother"),
    ("Hard", "Who painted 'The Son of Man'?", "Rene Magritte", ["Salvador Dali", "Max Ernst", "Giorgio de Chirico"], "The Son of Man"),
    ("Easy", "What is this material?", "Oil Paint", ["Acrylic", "Watercolor", "Gouache"], "Oil paint"),
    ("Medium", "Who sculpted 'The Pieta'?", "Michelangelo", ["Donatello", "Bernini", "Rodin"], "Pietà (Michelangelo)"),
    ("Hard", "Identify this painting.", "Las Meninas", ["The Night Watch", "The Third of May 1808", "The Burial of the Count of Orgaz"], "Las Meninas"),
    ("Medium", "Who is the artist?", "Georgia O'Keeffe", ["Frida Kahlo", "Mary Cassatt", "Tamara de Lempicka"], "Georgia O'Keeffe"),
    ("Easy", "What is this?", "Chisel", ["Hammer", "Brush", "Palette"], "Chisel"),
    ("Hard", "Identify this art movement.", "Baroque", ["Renaissance", "Rococo", "Neoclassicism"], "The Night Watch")
]

animals = [
    ("Easy", "What animal is this?", "Elephant", ["Rhino", "Hippo", "Buffalo"], "Elephant"),
    ("Easy", "Identify this big cat.", "Tiger", ["Lion", "Leopard", "Jaguar"], "Tiger"),
    ("Medium", "This pattern belongs to?", "Zebra", ["Giraffe", "Okapi", "Lemur"], "Zebra"),
    ("Medium", "What bird is this?", "Toucan", ["Hornbill", "Parrot", "Macaw"], "Toucan"),
    ("Hard", "Identify this reptile.", "Chameleon", ["Iguana", "Gecko", "Monitor Lizard"], "Chameleon"),
    ("Easy", "What is this marine animal?", "Clownfish", ["Goldfish", "Pufferfish", "Angelfish"], "Clownfish"),
    ("Medium", "This eye belongs to?", "Cat", ["Dog", "Fox", "Wolf"], "Cat eye"),
    ("Hard", "What animal is this close-up of?", "Giraffe", ["Leopard", "Cheetah", "Hyena"], "Giraffe"),
    ("Easy", "Name this bear.", "Polar Bear", ["Grizzly Bear", "Panda", "Brown Bear"], "Polar Bear"),
    ("Medium", "What insect is this?", "Monarch Butterfly", ["Moth", "Dragonfly", "Ladybug"], "Monarch Butterfly"),
    ("Easy", "Identify this dog breed.", "Golden Retriever", ["Labrador", "Beagle", "Poodle"], "Golden Retriever"),
    ("Medium", "What is this marsupial?", "Kangaroo", ["Wallaby", "Koala", "Wombat"], "Kangaroo"),
    ("Hard", "Name this sea creature.", "Octopus", ["Squid", "Cuttlefish", "Jellyfish"], "Octopus"),
    ("Easy", "What bird is this?", "Penguin", ["Puffin", "Seagull", "Albatross"], "Penguin"),
    ("Medium", "Identify this predator.", "Wolf", ["Coyote", "Fox", "Jackal"], "Wolf"),
    ("Hard", "What is this amphibian?", "Axolotl", ["Salamander", "Newt", "Frog"], "Axolotl"),
    ("Easy", "Name this farm animal.", "Cow", ["Horse", "Sheep", "Goat"], "Cow"),
    ("Medium", "Identify this primate.", "Gorilla", ["Chimpanzee", "Orangutan", "Baboon"], "Gorilla"),
    ("Hard", "What bird is this?", "Peacock", ["Pheasant", "Turkey", "Grouse"], "Peacock"),
    ("Easy", "What is this?", "Lion", ["Tiger", "Leopard", "Cheetah"], "Lion"),
    ("Medium", "Identify this owl.", "Snowy Owl", ["Barn Owl", "Great Horned Owl", "Tawny Owl"], "Snowy Owl"),
    ("Hard", "Name this whale.", "Orca", ["Blue Whale", "Humpback Whale", "Sperm Whale"], "Orca"),
    ("Easy", "What insect is this?", "Honey Bee", ["Wasp", "Hornet", "Fly"], "Honey Bee"),
    ("Medium", "Identify this rodent.", "Capybara", ["Beaver", "Guinea Pig", "Hamster"], "Capybara"),
    ("Hard", "What is this?", "Platypus", ["Beaver", "Otter", "Echidna"], "Platypus"),
    ("Easy", "Name this reptile.", "Turtle", ["Tortoise", "Terrapin", "Crab"], "Sea Turtle"),
    ("Medium", "Identify this shark.", "Hammerhead Shark", ["Great White Shark", "Tiger Shark", "Bull Shark"], "Hammerhead Shark"),
    ("Hard", "What animal is this?", "Red Panda", ["Raccoon", "Fox", "Lemur"], "Red Panda"),
    ("Easy", "What is this?", "Giant Panda", ["Polar Bear", "Black Bear", "Grizzly Bear"], "Giant Panda"),
    ("Medium", "Identify this cat.", "Leopard", ["Cheetah", "Jaguar", "Cougar"], "Leopard"),
    ("Hard", "Name this bird.", "Kingfisher", ["Hummingbird", "Woodpecker", "Blue Jay"], "Kingfisher"),
    ("Easy", "What is this?", "Frog", ["Toad", "Newt", "Salamander"], "Frog"),
    ("Medium", "Identify this arachnid.", "Tarantula", ["Black Widow", "Scorpion", "Wolf Spider"], "Tarantula"),
    ("Hard", "What animal is this?", "Pangolin", ["Armadillo", "Anteater", "Aardvark"], "Pangolin"),
    ("Easy", "Name this animal.", "Horse", ["Donkey", "Mule", "Zebra"], "Horse"),
    ("Medium", "Identify this deer.", "Moose", ["Elk", "Reindeer", "Caribou"], "Moose"),
    ("Hard", "What is this?", "Komodo Dragon", ["Iguana", "Monitor Lizard", "Crocodile"], "Komodo Dragon"),
    ("Easy", "What is this?", "Dolphin", ["Shark", "Whale", "Porpoise"], "Dolphin"),
    ("Medium", "Identify this bird.", "Flamingo", ["Stork", "Heron", "Crane"], "Flamingo"),
    ("Hard", "Name this animal.", "Sloth", ["Koala", "Monkey", "Lemur"], "Sloth"),
    ("Easy", "What is this?", "Rabbit", ["Hare", "Guinea Pig", "Hamster"], "Rabbit"),
    ("Medium", "Identify this crab.", "Hermit Crab", ["King Crab", "Fiddler Crab", "Lobster"], "Hermit Crab"),
    ("Hard", "What is this?", "Tapir", ["Pig", "Boar", "Anteater"], "Tapir"),
    ("Easy", "Name this insect.", "Ladybug", ["Beetle", "Ant", "Fly"], "Ladybug"),
    ("Medium", "Identify this jellyfish.", "Jellyfish", ["Squid", "Octopus", "Coral"], "Jellyfish"),
    ("Hard", "What animal is this?", "Narwhal", ["Beluga", "Dolphin", "Walrus"], "Narwhal"),
    ("Easy", "What is this?", "Swan", ["Duck", "Goose", "Pelican"], "Swan"),
    ("Medium", "Identify this bat.", "Fruit Bat", ["Vampire Bat", "Microbat", "Flying Squirrel"], "Megabat"),
    ("Hard", "Name this fish.", "Pufferfish", ["Lionfish", "Angelfish", "Tuna"], "Tetraodontidae"),
    ("Easy", "What is this?", "Squirrel", ["Chipmunk", "Rat", "Mouse"], "Squirrel")
]

food = [
    ("Easy", "What dish is this?", "Pizza", ["Lasagna", "Calzone", "Pasta"], "Pizza"),
    ("Easy", "Identify this Japanese food.", "Sushi", ["Ramen", "Tempura", "Udon"], "Sushi"),
    ("Medium", "What is this pastry?", "Croissant", ["Bagel", "Donut", "Pretzel"], "Croissant"),
    ("Medium", "Identify this Mexican dish.", "Tacos", ["Burrito", "Quesadilla", "Enchilada"], "Taco"),
    ("Medium", "What is this sweet treat?", "Macaron", ["Cookie", "Cupcake", "Muffin"], "Macaron"),
    ("Easy", "Name this fast food item.", "Hamburger", ["Hot Dog", "Sandwich", "Taco"], "Hamburger"),
    ("Hard", "What is this Spanish dish?", "Paella", ["Risotto", "Jambalaya", "Biryani"], "Paella"),
    ("Medium", "Identify this noodle soup.", "Ramen", ["Pho", "Laksa", "Miso Soup"], "Ramen"),
    ("Hard", "What is this snack?", "Pretzel", ["Bagel", "Donut", "Churro"], "Pretzel"),
    ("Medium", "Name this Indian bread.", "Naan", ["Roti", "Pita", "Tortilla"], "Naan"),
    ("Easy", "What fruit is this?", "Strawberry", ["Raspberry", "Cherry", "Apple"], "Strawberry"),
    ("Medium", "Identify this dessert.", "Cheesecake", ["Pie", "Tart", "Brownie"], "Cheesecake"),
    ("Hard", "What is this dish?", "Pad Thai", ["Chow Mein", "Lo Mein", "Fried Rice"], "Pad Thai"),
    ("Easy", "Name this vegetable.", "Broccoli", ["Cauliflower", "Spinach", "Kale"], "Broccoli"),
    ("Medium", "Identify this breakfast item.", "Pancakes", ["Waffles", "French Toast", "Crepes"], "Pancake"),
    ("Hard", "What is this Middle Eastern dish?", "Falafel", ["Hummus", "Kebab", "Shawarma"], "Falafel"),
    ("Easy", "What is this drink?", "Latte", ["Espresso", "Tea", "Juice"], "Latte"),
    ("Medium", "Identify this salad.", "Caesar Salad", ["Greek Salad", "Cobb Salad", "Garden Salad"], "Caesar Salad"),
    ("Hard", "Name this French dish.", "Ratatouille", ["Coq au Vin", "Beef Bourguignon", "Souffle"], "Ratatouille"),
    ("Easy", "What is this?", "Chocolate", ["Candy", "Cake", "Cookie"], "Chocolate"),
    ("Medium", "Identify this dip.", "Guacamole", ["Salsa", "Hummus", "Queso"], "Guacamole"),
    ("Hard", "What is this Korean dish?", "Kimchi", ["Bibimbap", "Bulgogi", "Tteokbokki"], "Kimchi"),
    ("Easy", "Name this fruit.", "Pineapple", ["Mango", "Banana", "Apple"], "Pineapple"),
    ("Medium", "Identify this soup.", "Tomato Soup", ["Chicken Soup", "Mushroom Soup", "Onion Soup"], "Tomato soup"),
    ("Hard", "What is this Italian dessert?", "Tiramisu", ["Cannoli", "Gelato", "Panna Cotta"], "Tiramisu"),
    ("Easy", "What is this?", "Ice Cream", ["Yogurt", "Sorbet", "Pudding"], "Ice Cream"),
    ("Medium", "Identify this bread.", "Baguette", ["Ciabatta", "Sourdough", "Rye"], "Baguette"),
    ("Hard", "Name this dumplings.", "Dim Sum", ["Gyoza", "Pierogi", "Ravioli"], "Dim Sum"),
    ("Easy", "What vegetable is this?", "Carrot", ["Potato", "Turnip", "Radish"], "Carrot"),
    ("Medium", "Identify this cheese.", "Swiss Cheese", ["Cheddar", "Mozzarella", "Brie"], "Swiss Cheese"),
    ("Hard", "What is this drink?", "Matcha", ["Green Tea", "Black Tea", "Oolong"], "Matcha"),
    ("Easy", "Name this food.", "French Fries", ["Potato Chips", "Hash Browns", "Tater Tots"], "French Fries"),
    ("Medium", "Identify this seafood.", "Shrimp Cocktail", ["Lobster", "Crab", "Oysters"], "Prawn cocktail"),
    ("Hard", "What is this Vietnamese soup?", "Pho", ["Ramen", "Udon", "Miso"], "Pho"),
    ("Easy", "What is this fruit?", "Watermelon", ["Melon", "Pumpkin", "Cucumber"], "Watermelon"),
    ("Medium", "Identify this cake.", "Cupcake", ["Muffin", "Brownie", "Cookie"], "Cupcake"),
    ("Hard", "Name this Turkish dish.", "Baklava", ["Delight", "Halva", "Kunafa"], "Baklava"),
    ("Easy", "What is this condiment?", "Ketchup", ["Mustard", "Mayo", "Relish"], "Ketchup"),
    ("Medium", "Identify this pasta.", "Spaghetti", ["Penne", "Fusilli", "Ravioli"], "Spaghetti"),
    ("Hard", "What is this cocktail?", "Mojito", ["Margarita", "Martini", "Daiquiri"], "Mojito"),
    ("Easy", "Name this nut.", "Almond", ["Peanut", "Cashew", "Walnut"], "Almond"),
    ("Medium", "Identify this breakfast.", "Eggs Benedict", ["Omelette", "Scrambled Eggs", "Fried Eggs"], "Eggs Benedict"),
    ("Hard", "What is this British dish?", "Fish and Chips", ["Pie and Mash", "Roast Dinner", "Bangers and Mash"], "Fish and chips"),
    ("Easy", "What fruit is this?", "Banana", ["Plantain", "Corn", "Zucchini"], "Banana"),
    ("Medium", "Identify this spice.", "Cinnamon", ["Nutmeg", "Clove", "Ginger"], "Cinnamon"),
    ("Hard", "Name this Greek dish.", "Moussaka", ["Souvlaki", "Gyro", "Spanakopita"], "Moussaka"),
    ("Easy", "What is this?", "Popcorn", ["Chips", "Nachos", "Pretzels"], "Popcorn"),
    ("Medium", "Identify this berry.", "Blueberry", ["Blackberry", "Raspberry", "Grape"], "Blueberry"),
    ("Hard", "What is this Japanese snack?", "Onigiri", ["Sushi", "Mochi", "Tempura"], "Onigiri"),
    ("Easy", "Name this drink.", "Orange Juice", ["Apple Juice", "Lemonade", "Soda"], "Orange Juice")
]

instruments = [
    ("Easy", "What instrument is this?", "Electric Guitar", ["Bass Guitar", "Acoustic Guitar", "Ukulele"], "Electric guitar"),
    ("Medium", "Identify this brass instrument.", "Saxophone", ["Trumpet", "Trombone", "Clarinet"], "Saxophone"),
    ("Easy", "What is this?", "Piano", ["Organ", "Harpsichord", "Synthesizer"], "Piano"),
    ("Medium", "Name this string instrument.", "Violin", ["Cello", "Viola", "Double Bass"], "Violin"),
    ("Hard", "Identify this percussion instrument.", "Djembe", ["Bongo", "Conga", "Snare Drum"], "Djembe"),
    ("Hard", "What is this?", "Harp", ["Lyre", "Lute", "Zither"], "Harp"),
    ("Medium", "Name this instrument.", "Trumpet", ["Trombone", "Tuba", "French Horn"], "Trumpet"),
    ("Medium", "Identify this.", "Acoustic Guitar", ["Electric Guitar", "Banjo", "Mandolin"], "Acoustic guitar"),
    ("Hard", "What instrument is being played?", "Bagpipes", ["Accordion", "Didgeridoo", "Harmonica"], "Bagpipes"),
    ("Medium", "Name this drum set component.", "Snare Drum", ["Bass Drum", "Tom-Tom", "Cymbal"], "Snare drum"),
    ("Easy", "What is this?", "Drum Kit", ["Percussion", "Cymbals", "Bongo"], "Drum kit"),
    ("Medium", "Identify this woodwind.", "Flute", ["Clarinet", "Oboe", "Recorder"], "Flute"),
    ("Hard", "Name this instrument.", "Cello", ["Violin", "Double Bass", "Viola"], "Cello"),
    ("Medium", "What is this?", "Ukulele", ["Guitar", "Banjo", "Mandolin"], "Ukulele"),
    ("Hard", "Identify this keyboard.", "Accordion", ["Piano", "Organ", "Melodica"], "Accordion"),
    ("Easy", "What instrument is this?", "Microphone", ["Speaker", "Amp", "Headphones"], "Microphone"),
    ("Medium", "Name this brass instrument.", "Trombone", ["Trumpet", "Tuba", "French Horn"], "Trombone"),
    ("Hard", "Identify this string instrument.", "Banjo", ["Guitar", "Ukulele", "Mandolin"], "Banjo"),
    ("Medium", "What is this?", "Clarinet", ["Flute", "Oboe", "Bassoon"], "Clarinet"),
    ("Hard", "Name this instrument.", "French Horn", ["Trumpet", "Tuba", "Trombone"], "French horn"),
    ("Easy", "What is this?", "Bongos", ["Congas", "Djembe", "Tabla"], "Bongo drum"),
    ("Medium", "Identify this.", "Harmonica", ["Kazoo", "Whistle", "Recorder"], "Harmonica"),
    ("Hard", "What is this large instrument?", "Double Bass", ["Cello", "Violin", "Viola"], "Double bass"),
    ("Medium", "Name this electronic instrument.", "Synthesizer", ["Piano", "Organ", "Keytar"], "Synthesizer"),
    ("Hard", "Identify this.", "Sitar", ["Guitar", "Lute", "Banjo"], "Sitar"),
    ("Easy", "What is this?", "Xylophone", ["Marimba", "Vibraphone", "Glockenspiel"], "Xylophone"),
    ("Medium", "Name this instrument.", "Mandolin", ["Guitar", "Ukulele", "Lute"], "Mandolin"),
    ("Hard", "Identify this wind instrument.", "Oboe", ["Clarinet", "Flute", "Bassoon"], "Oboe"),
    ("Medium", "What is this?", "Tuba", ["Trumpet", "Trombone", "Sousaphone"], "Tuba"),
    ("Hard", "Name this percussion.", "Tambourine", ["Maracas", "Castanets", "Triangle"], "Tambourine"),
    ("Easy", "What is this?", "Triangle", ["Bell", "Chime", "Gong"], "Triangle (instrument)"),
    ("Medium", "Identify this.", "Maracas", ["Shakers", "Tambourine", "Castanets"], "Maracas"),
    ("Hard", "What is this?", "Didgeridoo", ["Alphorn", "Vuvuzela", "Pipe"], "Didgeridoo"),
    ("Medium", "Name this instrument.", "Bass Guitar", ["Electric Guitar", "Acoustic Guitar", "Double Bass"], "Bass guitar"),
    ("Hard", "Identify this.", "Pan Flute", ["Harmonica", "Recorder", "Ocarina"], "Pan flute"),
    ("Easy", "What is this?", "Gong", ["Cymbal", "Bell", "Drum"], "Gong"),
    ("Medium", "Name this.", "Cowbell", ["Triangle", "Woodblock", "Agogo"], "Cowbell (instrument)"),
    ("Hard", "Identify this.", "Koto", ["Shamisen", "Biwa", "Guzheng"], "Koto (instrument)"),
    ("Medium", "What is this?", "Recorder", ["Flute", "Clarinet", "Whistle"], "Recorder (musical instrument)"),
    ("Hard", "Name this.", "Lute", ["Guitar", "Mandolin", "Oud"], "Lute"),
    ("Easy", "What is this?", "Metronome", ["Tuner", "Timer", "Clock"], "Metronome"),
    ("Medium", "Identify this.", "Music Stand", ["Easel", "Tripod", "Podium"], "Music stand"),
    ("Hard", "What is this?", "Baton", ["Stick", "Wand", "Rod"], "Baton (conducting)"),
    ("Medium", "Name this.", "Amplifier", ["Speaker", "Subwoofer", "Monitor"], "Guitar amplifier"),
    ("Hard", "Identify this.", "Turntable", ["CD Player", "Cassette Deck", "Radio"], "Phonograph"),
    ("Easy", "What is this?", "Headphones", ["Earbuds", "Speaker", "Mic"], "Headphones"),
    ("Medium", "Name this.", "Vinyl Record", ["CD", "Cassette", "Tape"], "Phonograph record"),
    ("Hard", "Identify this.", "Cassette Tape", ["Vinyl", "CD", "8-Track"], "Cassette tape"),
    ("Medium", "What is this?", "Mic Stand", ["Tripod", "Light Stand", "Pole"], "Microphone stand"),
    ("Hard", "Name this.", "Mixing Console", ["Synthesizer", "Computer", "Amplifier"], "Mixing console")
]

space = [
    ("Easy", "What planet is this?", "The Moon", ["Mercury", "Venus", "Mars"], "Moon"),
    ("Medium", "Identify this planet.", "Jupiter", ["Saturn", "Mars", "Neptune"], "Jupiter"),
    ("Medium", "Which planet has these rings?", "Saturn", ["Jupiter", "Uranus", "Neptune"], "Saturn"),
    ("Easy", "Name this star.", "The Sun", ["Proxima Centauri", "Sirius", "Betelgeuse"], "Sun"),
    ("Hard", "What is this celestial object?", "Pillars of Creation", ["Crab Nebula", "Andromeda Galaxy", "Black Hole"], "Pillars of Creation"),
    ("Hard", "Identify this galaxy.", "Andromeda Galaxy", ["Milky Way", "Triangulum Galaxy", "Whirlpool Galaxy"], "Andromeda Galaxy"),
    ("Medium", "What is this red planet?", "Mars", ["Venus", "Mercury", "Jupiter"], "Mars"),
    ("Hard", "Name this dwarf planet.", "Pluto", ["Eris", "Ceres", "Haumea"], "Pluto"),
    ("Medium", "What phenomenon is this?", "Aurora Borealis", ["Solar Flare", "Comet Tail", "Supernova"], "Aurora"),
    ("Hard", "What is this?", "Nebula", ["Galaxy", "Star Cluster", "Black Hole"], "Nebula"),
    ("Easy", "What is this object?", "Earth", ["Mars", "Venus", "Neptune"], "Earth"),
    ("Medium", "Identify this vehicle.", "Space Shuttle", ["Apollo 11", "Falcon 9", "Soyuz"], "Space Shuttle"),
    ("Hard", "What is this?", "ISS", ["Mir", "Skylab", "Tiangong"], "International Space Station"),
    ("Easy", "Name this phenomenon.", "Solar Eclipse", ["Lunar Eclipse", "Full Moon", "New Moon"], "Solar eclipse"),
    ("Medium", "Identify this object.", "Asteroid", ["Comet", "Meteor", "Planet"], "Asteroid"),
    ("Hard", "What is this?", "Black Hole", ["Neutron Star", "Supernova", "Quasar"], "Black hole"),
    ("Easy", "What is this?", "Astronaut", ["Pilot", "Diver", "Soldier"], "Astronaut"),
    ("Medium", "Identify this planet.", "Venus", ["Mars", "Mercury", "Earth"], "Venus"),
    ("Hard", "Name this rover.", "Mars Rover", ["Lunar Rover", "Moon Buggy", "Voyager"], "Mars rover"),
    ("Medium", "What is this?", "Comet", ["Asteroid", "Meteor", "Star"], "Comet"),
    ("Easy", "Identify this object.", "Rocket", ["Plane", "Missile", "Drone"], "Rocket"),
    ("Hard", "What galaxy is this?", "Milky Way", ["Andromeda", "Triangulum", "Sombrero"], "Milky Way"),
    ("Medium", "Name this planet.", "Neptune", ["Uranus", "Saturn", "Jupiter"], "Neptune"),
    ("Hard", "Identify this moon.", "Europa", ["Titan", "Io", "Ganymede"], "Europa (moon)"),
    ("Easy", "What is this?", "Telescope", ["Microscope", "Binoculars", "Camera"], "Telescope"),
    ("Medium", "Identify this constellation.", "Orion", ["Ursa Major", "Cassiopeia", "Scorpius"], "Orion (constellation)"),
    ("Hard", "What is this?", "Supernova", ["Black Hole", "Nebula", "Star"], "Supernova"),
    ("Medium", "Name this object.", "Satellite", ["Station", "Probe", "Rocket"], "Satellite"),
    ("Hard", "Identify this phenomenon.", "Meteor Shower", ["Comet", "Asteroid", "Aurora"], "Meteor shower"),
    ("Easy", "What is this?", "Craters", ["Valleys", "Mountains", "Lakes"], "Impact crater"),
    ("Medium", "Identify this planet.", "Uranus", ["Neptune", "Saturn", "Jupiter"], "Uranus"),
    ("Hard", "Name this telescope.", "Hubble", ["James Webb", "Spitzer", "Chandra"], "Hubble Space Telescope"),
    ("Medium", "What is this?", "Solar Panel", ["Antenna", "Radiator", "Mirror"], "Solar panel"),
    ("Hard", "Identify this moon.", "Titan", ["Europa", "Io", "Callisto"], "Titan (moon)"),
    ("Easy", "What is this?", "Space Suit", ["Flight Suit", "Wetsuit", "Hazmat Suit"], "Space suit"),
    ("Medium", "Name this object.", "Meteorite", ["Meteor", "Asteroid", "Rock"], "Meteorite"),
    ("Hard", "Identify this nebula.", "Horsehead Nebula", ["Crab Nebula", "Eagle Nebula", "Orion Nebula"], "Horsehead Nebula"),
    ("Medium", "What is this?", "Capsule", ["Shuttle", "Station", "Rocket"], "Space capsule"),
    ("Hard", "Name this mission.", "Apollo 11", ["Apollo 13", "Gemini 4", "Mercury 7"], "Apollo 11"),
    ("Easy", "What is this?", "Full Moon", ["Crescent Moon", "New Moon", "Gibbous Moon"], "Full moon"),
    ("Medium", "Identify this planet.", "Mercury", ["Mars", "Venus", "Pluto"], "Mercury (planet)"),
    ("Hard", "What is this theory?", "Big Bang", ["String Theory", "Multiverse", "Evolution"], "Big Bang"),
    ("Medium", "Name this phase.", "Crescent Moon", ["Full Moon", "Half Moon", "New Moon"], "Crescent moon"),
    ("Hard", "Identify this star.", "Sirius", ["Polaris", "Betelgeuse", "Rigel"], "Sirius"),
    ("Easy", "What is this?", "Observatory", ["Planetarium", "Laboratory", "Factory"], "Observatory"),
    ("Medium", "Name this event.", "Lunar Eclipse", ["Solar Eclipse", "Solstice", "Equinox"], "Lunar eclipse"),
    ("Hard", "Identify this constellation.", "Ursa Major", ["Ursa Minor", "Orion", "Leo"], "Ursa Major"),
    ("Medium", "What is this?", "Space Debris", ["Asteroid Belt", "Meteor Shower", "Star Cluster"], "Space debris"),
    ("Hard", "Name this probe.", "Voyager", ["Pioneer", "New Horizons", "Cassini"], "Voyager program"),
    ("Easy", "What is this?", "Stars", ["Planets", "Meteors", "Satellites"], "Star")
]

# --- 2. FETCH LOGIC (Optimized) ---

def get_wiki_image(search_term):
    """Fetches the main image URL from Wikipedia given a search term."""
    url = "https://en.wikipedia.org/w/api.php"
    params = {
        "action": "query",
        "format": "json",
        "prop": "pageimages",
        "titles": search_term,
        "pithumbsize": 600
    }
    # ✅ FIX: Wikipedia requires a User-Agent or it blocks requests
    headers = {
        "User-Agent": "KnowItAllQuizBot/1.0 (contact@example.com)"
    }
    
    try:
        response = requests.get(url, params=params, headers=headers, timeout=10)
        response.raise_for_status() # Raise error for 4xx/5xx codes
        
        data = response.json()
        pages = data.get("query", {}).get("pages", {})
        
        for page_id in pages:
            if "thumbnail" in pages[page_id]:
                return pages[page_id]["thumbnail"]["source"]
                
    except Exception as e:
        # print(f"⚠️ Error fetching {search_term}: {e}") # Optional: keep logs clean
        pass
    
    # Fallback if no image found
    return "https://placehold.co/600x400/000000/FFF?text=Image+Not+Found"

def create_entry(category, difficulty, question, answer, incorrect, query):
    url = get_wiki_image(query)
    # print(f"✅ [{category}] {query} -> {url}")
    return {
        "Category": category,
        "Type": "image",
        "Difficulty": difficulty,
        "Question": question,
        "MediaPayload": url,
        "CorrectAnswer": answer,
        "IncorrectAnswers": incorrect
    }

# --- 3. PARALLEL EXECUTION ---

all_data = []
tasks = []

# Combine all lists with their categories
full_workload = []
for q in landmarks: full_workload.append(("Landmarks", *q))
for q in art:       full_workload.append(("Art", *q))
for q in animals:   full_workload.append(("Animals", *q))
for q in food:      full_workload.append(("Food", *q))
for q in instruments: full_workload.append(("Instruments", *q))
for q in space:     full_workload.append(("Space", *q))

print(f"🚀 Starting fast fetch for {len(full_workload)} questions...")

with concurrent.futures.ThreadPoolExecutor(max_workers=20) as executor:
    # Submit all tasks
    future_to_query = {executor.submit(create_entry, *item): item for item in full_workload}
    
    for i, future in enumerate(concurrent.futures.as_completed(future_to_query)):
        try:
            result = future.result()
            all_data.append(result)
            if i % 10 == 0:
                print(f"⚡ Progress: {i}/{len(full_workload)}")
        except Exception as exc:
            print(f"Generaton Error: {exc}")

# Save File
with open("questions.json", "w", encoding="utf-8") as f:
    json.dump(all_data, f, indent=2)

print(f"\n🎉 SUCCESS! Generated questions.json with {len(all_data)} items.")


