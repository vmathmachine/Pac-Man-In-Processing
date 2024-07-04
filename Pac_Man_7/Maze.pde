import java.util.Iterator;
import java.util.Map;

public static class Maze implements Iterable<Actor> {  //a maze of grid squares

  //////////////////////////// ATTRIBUTES //////////////////////////
  
  //positional & dimensional parameters
  int w, h;   //width & height
  int cell;   //cell width/height in pixels
  int cx, cy; //x,y position of top left corner
  
  private Grid[][] maze; //the maze of grid squares
  
  //zoning
  Hitbox tunnel;     //used to characterize whether something is in the tunnel
  Hitbox ghostHouse; //used to characterize whether something is in the ghost house
  
  //display attributes (soon to be moved?????)
  PImage visual;    //the background image
  PImage altVisual; //the flashing background image
  PVector topLeft;  //the atomic position of the top left of the image
  
  //entities in the maze (addressed by name)
  ArrayList<Actor> actors = new ArrayList<Actor>(); //the actors in the level
  
  //the game this maze lives in
  Game game;
  
  /////// GAME SPECIFIC ATTRIBUTES ////////
  
  //game-consistent attributes (does not change each level)
  int lives=0;        //how many lives we have (-1=game over, default to game over)
  int score= 0;       //what the score is (0 at beginning of game)
  
  //cheats
  boolean cheats    =false; //whether or not we've used cheats in this run
  boolean invincible=false; //whether Pac-Man (and other Pac creatures) are invincible
  
  //level specific (changes/resets w/ each level):
  int level = 1;        //which level we're on (init to 1)
  int levelMap = 1;     //which level the game acts like we're on, depending on if we're on normal or hard mode
  int dotsLeft=244;     //how many dots are left (244 at the beginning of each level)
  int frightTimer=0;    //how many more frames energizer will stay in effect (when 0, it's not in effect)
  int comboCount=0;     //the number of consecutive ghosts that have been eaten on the same energizer pellet
  int levelTimer=0;     //how long the level has gone on for (resets when level starts or Pac-Man dies, pauses during fright mode)
  
  //determines when to release the ghosts from the ghost house
  boolean doGlobalDotCounter=false; //true if global dot counter is activated. See Pac-Man dossier for more details
  int globalDotCounter=0;           //the global dot counter. See Pac-Man dossier for more details
  int timeSinceLastDot=0;           //time since Pac-Man last ate a dot
  
  String player1 = "Pac-Man", player2 = "Pac-Man"; //the player(s) that we play as for this particular maze
  
  //////////////////////////////// CONSTRUCTORS ////////////////////////////////////
  
  Maze() { }
  
  Maze(int x_, int y_, int w_, int h_, int cell_, boolean init) { //loads a maze without a file (init = whether to initialize the values or leave them null)
    cx=x_; cy=y_; //set position
    w=w_; h=h_;   //set dimensions
    cell = cell_; //set cell size
    maze = new Grid[w][h]; //initialize grid maze
    
    if(init) { //if we want to initialize each grid square,
      for(int i=0;i<w;i++) for(int j=0;j<h;j++) { maze[i][j] = new Grid(); } //initialize each grid square
    }
    //otherwise, we leave them all null
  }
  
  Maze(int x_, int y_, int w_, int h_, int cell_, BufferedReader read) { //loads a maze from a file (given dimensions)
    this(x_,y_,w_,h_,cell_, false); //initialize maze given parameters
    
    loadMaze(read);        //load the maze from the file
  }
  
  void loadMaze(BufferedReader read) { //loads maze from file
    
    for(int y=0;y<h;y++) { //loop through all lines
      String line;
      try { line = read.readLine(); }  //try to read this line
      catch(IOException ex) { throw new RuntimeException("Maze loading error: expected "+h+" lines, but got "+y); } //error: not enough lines
      
      if(line.length()<w) { throw new RuntimeException("Maze loading error: line "+(y+1)+" should be "+w+" long, but was instead "+line.length()+" long"); } //error: bad dimensions
      
      for(int x=0;x<w;x++) {
        maze[x][y] = new Grid(line.charAt(x)); //load each grid square based on the character
      }
    }
  }
  
  ///////////////////////// GETTERS //////////////////////////
  
  Actor get(String name) { //grabs Actor with a specific name
    for(Actor act : actors) { //loop through all actors
      if(act.name.equals(name)) { return act; } //if the actor has the same name, return it
    }
    return null; //if we find no match, return null
  } //this method is TECHNICALLY fast, but only because there are so few options. If there were a lot of options, it'd be a good idea to invest in a HashMap which maps each name to the index of an actor
  //the reason we don't already use hashmaps for this is because it would put the actors in the wrong order
  
  Grid get(int x, int y) { return maze[Math.floorMod(x,w)][Math.floorMod(y,h)]; }
  Grid get(IVector v) { return maze[Math.floorMod(v.x,w)][Math.floorMod(v.y,h)]; }
  
  Item getItem(int x, int y) { return maze[Math.floorMod(x,w)][Math.floorMod(y,h)].getItem(); }
  Item getItem(IVector v) { return maze[Math.floorMod(v.x,w)][Math.floorMod(v.y,h)].getItem(); }
  
  void setItem(int x, int y, Item item) { maze[Math.floorMod(x,w)][Math.floorMod(y,h)].setItem(item); }
  void setItem(IVector v, Item item) { maze[Math.floorMod(v.x,w)][Math.floorMod(v.y,h)].setItem(item); }
  
  ///////////////////////// SETTERS //////////////////////////
  
  Maze add(Actor act) { actors.add(act); return this; } //adds an actor to the list
  Maze remove(Actor act) { actors.remove(act); return this; } //removes an actor from the list
  Maze setGame(Game game2) { game = game2; for(Actor actor : this) { actor.game=game2; } return this; } //sets the game
  
  Maze clearDots() { //removes all dots
    for(int x=0;x<w;x++) for(int y=0;y<h;y++) {
      maze[x][y].setItem(Item.NONE); //remove all items
    }
    dotsLeft = 0; //no dots left
    return this;  //return result
  }
  
  Maze setLevel(final int lev) { //sets the level
    level    = lev;                                      //set level
    levelMap = Game_Values.levelMapping(lev, game.hard); //set the mapped level
    return this;                                         //return result
  }
  
  void incrementLives() { if(lives!=Integer.MIN_VALUE) { ++lives; } } //increment lives (unless infinite)
  void decrementLives() { if(lives!=Integer.MIN_VALUE) { --lives; } } //decrement lives (unless infinite)
  
  ///////////////////////// DRAWING/DISPLAY /////////////////////////////////////////
  
  void makeMazePicture(PGraphics g) { //draws the maze when there isn't a dedicated png file (mostly used for testing)
    g.fill(0); g.rect(cx,cy,cell*w,cell*h);
    for(int x=0;x<w;x++) for(int y=0;y<h;y++) { //loop through all grid squares
      switch(maze[x][y].specifier()) {
        case "pac-dot": /*g.fill(255,183,174); g.noStroke(); g.square(cell*(x+0.5)+cx-1,cell*(y+0.5)+cy-1,2);*/ break;
        case "energizer": /*g.fill(255,183,174); g.noStroke(); g.square(cell*(x+0.5)+cx-3,cell*(y+0.5)+cy-3,6);*/ break;
        case "wall": g.fill(0,0,255); g.noStroke(); g.rect(cell*x+cx,cell*y+cy,cell,cell); break;
        case "gate": g.fill(255); g.noStroke(); g.rect(cell*x+cx,cell*y+cy,cell,cell); break;
        case "complex wall":
          g.fill(0,0,255);
          if(maze[x][y].   up()) { g.rect(cell*x+cx,cell*y+cy,cell,0.25*cell); }
          if(maze[x][y]. down()) { g.rect(cell*x+cx,cell*(y+1)+cy,cell,-0.25*cell); }
          if(maze[x][y]. left()) { g.rect(cell*x+cx,cell*y+cy,0.25*cell,cell); }
          if(maze[x][y].right()) { g.rect(cell*(x+1)+cx,cell*y+cy,-0.25*cell,cell); }
        break;
      }
    }
  }
  
  /////////////////////// DEFAULT FUNCTIONS /////////////////////////////////////////
  
  @Override
  Maze clone() {
    Maze clone = new Maze(cx,cy,w,h,cell,false);
    for(int x=0;x<w;x++) for(int y=0;y<h;y++) {
      clone.maze[x][y] = maze[x][y].clone();
    }
    clone.tunnel=tunnel; clone.ghostHouse=ghostHouse;
    return clone;
  }
  
  @Override
  public Iterator<Actor> iterator() {
    return actors.iterator();
  }
  
  //temporary functions
  
  void remove(String name) { actors.remove(get(name)); }
}
