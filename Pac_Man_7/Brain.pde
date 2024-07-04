public static class Brain { //the Brain (AKA Artificial Intelligence) of the Actors, encoded into a class
  
  //Each actor in Pac-Man has a very simple brain: it finds a target, then it either moves towards or away from that target
  //In order to move towards or away from that target, it simply looks through 4 options, throws away whichever one would require turning around, then picks whichever one brings it closer to/farther from that target
  //If the only option is to turn around, it simply turns around
  
  ////////////////////////////// ATTRIBUTES /////////////////////////////////
  
  ////// DYNAMIC ////////////
  
  Actor body; //the Actor this brain belongs to
  
  Behavior behavior; //the Actor's CURRENT behavior
  
  TargetFinder targetter; //the function we use to find our target AND our pathfinding mode
  
  Actor variables[] = new Actor[2]; //all Actors which may influence the behavior of this AI
  //Actor 0 is often Pac-Man, though for Pac-Man it's Pinky. For Inky and Pac-Man, Actor 1 is Blinky, but for everyone else, it's null
  
  /////// STATIC MEMBERS ///////////
  
  //below are all the methods that may be used to find a target
  
  static Object[] toward(IVector v) { return new Object[] {PathFinding.TOWARD,             v}; } //returns an array that means "target towards this vector"
  static Object[]   away(IVector v) { return new Object[] {PathFinding.  AWAY,             v}; } //returns an array that means "target away from this vector"
  static Object[] randomDirection() { return new Object[] {PathFinding.RANDOM, new IVector()}; } //returns an array that means "go in any random direction"
  
  static TargetFinder targetTowardsFixedTile(final IVector v) { //returns a target finder that simply moves you towards a fixed tile
    return new TargetFinder() { public Object[] findTarget(Actor body, Actor... vars) { return toward(v); } };
  }
  
  
  //below are all the possible AIs
  
  //chase mode:
  static HashMap<String, TargetFinder> chase = new HashMap<String, TargetFinder>() {{ //a hashmap of all 4 of the ghost's Pac-Man hunting AIs
    put("Blinky", new TargetFinder() { public Object[] findTarget(Actor body, Actor... vars) { //Blinky: always targets towards Pac-Man
      return toward(vars[0].tile);                                                             //(vars[0] is Pac-Man)
    }});
    put( "Pinky", new TargetFinder() { public Object[] findTarget(Actor body, Actor... vars) { //Pinky: always targets the tile 4 steps ahead of Pac-Man
      return toward(vars[0].tile.copy().glitchedAdd(vars[0].cDir.copy().shiftLeft(2)));        //note we're using the glitched add, which causes the direction up to become diagonal up-left (just like in the arcade title)
    }});
    put(  "Inky", new TargetFinder() { public Object[] findTarget(Actor body, Actor... vars) { //Inky: targets in the spot such that the space 2 ahead of Pac-Man is halfway between that target tile and Blinky's position
      IVector intermediate = vars[0].tile.copy().glitchedAdd(vars[0].cDir.copy().shiftLeft(1)); //find the spot 2 tiles in front of Pac-Man (again, using glitched add)
      return toward(intermediate.shiftLeft(1).sub(vars[1].tile));                               //Now, multiply by 2 and subtract Blinky's position (the functional inverse of the midpoint)
    }});
    put( "Clyde", new TargetFinder() { public Object[] findTarget(Actor body, Actor... vars) { //Clyde: targets towards Pac-Man if he's 8 or more tiles away, targets towards the bottom left otherwise
      if(body.tile.distSq(vars[0].tile) < 64) { return toward(new IVector( 2,31)); } //if closer than 8 tiles: target the bottom left
      else                                    { return toward(vars[0].tile);       } //otherwise, target Pac-Man
    }});
  }};
  
  //scatter mode:
  static HashMap<String, TargetFinder> scatter = new HashMap<String, TargetFinder>() {{ //a hashmap of all the places ghosts target to in scatter mode:
    put("Pinky", targetTowardsFixedTile(new IVector( 4,-4))); //pinky: top left
    put( "Inky", targetTowardsFixedTile(new IVector(29,31))); // inky: bottom right
    put("Clyde", targetTowardsFixedTile(new IVector( 2,31))); //clyde: bottom left
    
    put("Blinky", new TargetFinder() { public Object[] findTarget(Actor body, Actor... vars) { //Blinky is special
      if(((Ghost)body).isElroy()) { return toward(vars[0].tile);       } //in cruise Elroy mode, we target towards Pac-Man
      else                        { return toward(new IVector(27,-4)); } //otherwise, target towards the top right
    }});
  }};
  
  //frightened mode:
  static TargetFinder random = new TargetFinder() { public Object[] findTarget(Actor body, Actor... vars) {
    return randomDirection(); //all ghosts, when in frightened mode, move in a random direction
  } };
  
  //base modes:
  static HashMap<String, TargetFinder> base_enter = new HashMap<String, TargetFinder>() {{ //entering the base (presumably after being eaten)
    put("Blinky", targetTowardsFixedTile(new IVector(16,15))); //Blinky & Pinky both go to the middle
    put( "Pinky", get("Blinky"));
    put(  "Inky", targetTowardsFixedTile(new IVector(15,31))); //Inky goes bottom left
    put( "Clyde", targetTowardsFixedTile(new IVector(17,31))); //Clyde goes bottom right
  }};
  
  static HashMap<String, TargetFinder> base_exit_1 = new HashMap<String, TargetFinder>() {{ //first step of exiting the base
    put( "Inky", targetTowardsFixedTile(new IVector(31,16))); // Inky just goes right
    put("Clyde", targetTowardsFixedTile(new IVector( 0,16))); //Clyde just goes left
  }};                                                         //Blinky & Pinky skip phase 1
  
  static TargetFinder base_entrance = targetTowardsFixedTile(new IVector(15,11)); //with this, we just target straight for the base entrance (usually either when eaten or in exit phase 2)
  
  static TargetFinder base_patrol = new TargetFinder() { public Object[] findTarget(Actor body, Actor... vars) { return new Object[] {PathFinding.PATROL, new IVector()}; } }; //when patrolling, we only move up & down
  
  //Pac-Man demo screen:
  static TargetFinder pacDemo = new TargetFinder() { public Object[] findTarget(Actor body, Actor... vars) { //on the demo screen, Pac-Man has a (very simple) AI programmed which tells him where to go
    if(vars[0].state == State.VULNERABLE) { return toward(vars[1].tile); } //if Blinky (vars[0]) is vulnerable, target towards Pinky (vars[1])
    else                                  { return away  (vars[1].tile); } //otherwise, target away from Pinky (vars[1])
  } };
  
  
  
  //BASE AIS: simply target towards the ghost house gate
  static TargetFinder base_middle   = targetTowardsFixedTile(new IVector(16,15));
  
  /////////////////////////////////// CONSTRUCTORS ///////////////////////////////
  
  Brain() { } //no Brain
  
  Brain(Actor actor, Behavior behavior) { //construct a brain using the actor
    body = actor;          //set the body
    body.brain = this;     //set the body's brain
    
    setBehavior(behavior); //set the behavior, and everything else will follow suit
  }
  
  //////////////////////////// GETTERS ////////////////////////
  
  Behavior getBehavior() { return behavior; }
  
  //////////////////////////// SETTERS ///////////////////////
  
  Brain setBehavior(final Behavior behavior) { //sets the behavior (and everything related)
    if(this.behavior == behavior) { return this; } //if the behavior is the same, short-circuit out
    
    this.behavior = behavior; //change the behavior
    
    if(body instanceof Pac) { //if it's a Pac creature:
      targetter = pacDemo;    //set the AI to the AI it uses in the demo screen
      variables[0] = body.maze.get("Blinky"); variables[1] = body.maze.get("Pinky"); //load the 2 ghosts which control its behavior
    }
    
    else switch(behavior) { //otherwise, switch the behavior:
      case CHASE: //chase mode:
        targetter = chase.get(body.name); //load up the chase mode targetting AI
        
        variables[0] = body.maze.get("Pac-Man"); //set the 0th variable to Pac-Man
        if(body.name.equals("Inky")) { variables[1] = body.maze.get("Blinky"); } //special case: if Inky, set the 1st variable to Blinky
      break;
      
      case SCATTER: //scatter mode:
        targetter = scatter.get(body.name); //load up the scatter mode targetting AI
        
        if(body.name.equals("Blinky")) { variables[0] = body.maze.get("Pac-Man"); } //for Blinky (who's sometimes cruise Elroy), set the 0th variable to Pac-Man
      break;
      
      case FRIGHTENED: targetter = random; break; //frightened mode: set pathfinding to random
      
      case BASE_EXIT_2: case EATEN: targetter = base_entrance; break; //base exit 2 / eaten mode: set pathfinding to fixed point
      
      case BASE_PATROL: targetter = base_patrol; break; //base patrol: return the built-in base patrolling mode
      
      case BASE_ENTER: targetter = base_enter.get(body.name); break; //entering the base: load up the base entry AI
      
      case BASE_EXIT_1: targetter = base_exit_1.get(body.name); break; //exiting the base, phase 1: load up the base exit AI
    }
    
    return this; //return result
  }
  
  //////////////////////////// PATHFINDING ////////////////////////////
  
  Object[] loadPathFinding() { //loads pathfinding attributes, namely the pathfinding mode and the target tile, respectively
    if(targetter==null) { println(body); new NullPointerException().printStackTrace(); }
    return targetter.findTarget(body, variables);
  }
  
  void setNextDirection(IVector tile) { //sets the new direction for the body
    Object[] loadPathFinding = loadPathFinding(); //load pathfinding attributes
    
    PathFinding mode = (PathFinding)loadPathFinding[0]; //cast to appropriate classes
    IVector   target = (IVector)    loadPathFinding[1];
    
    //now, we take a look at where the ghost will be when they reach the next tile, then analyze each of the 4 directions it can go in (right, down, left, up, in that order)
    
    int[] distances = loadDistances(mode, target); //First, load an array of the distances between the target and the 4 locations we can move to.
    //If in AWAY mode, this stores the distances, while in TOWARDS mode, this negates the distances. This is done so that we can choose whichever index is the biggest
    //Thus, distances essentially stores our preference towards each direction. Now, we just have to eliminate all the impossible directions
    
    IVector[] directions = {new IVector(1,0), new IVector(0,1), new IVector(-1,0), new IVector(0,-1)}; //a list of all directions in order
        
    for(int n=0;n<4;n++) { //loop through all 4 directions
      if(directions[n^2].equals(body.cDir) ||                    //if this points away from the current direction,
         behavior==Behavior.BASE_PATROL && directions[n].y==0 || //or we're in base mode and this is sideways,
         body.willCollide(tile, directions[n], true)) {          //or going this direction would cause a collision
        distances[n] = Integer.MIN_VALUE;                        //eliminate it as a possibility by setting it to the smallest integer
      }
    }
    
    int maxIndex = -1, maxValue = Integer.MIN_VALUE; //now, we compute the maximum (initialize to the worst possible value)
    for(int n=0;n<4;n++) {                           //loop through all directions
      if(distances[n] >= maxValue) { maxIndex = n; maxValue = distances[n]; } //if this distance is at least AS good as our current best option, make it our new best option
    }
    if(maxValue == Integer.MIN_VALUE) { //special case: if there were no viable options:
      body.nDir.set(body.cDir).neg();   //make turning around a viable option again, then take that option
    }
    else { body.nDir.set(directions[maxIndex]); } //otherwise, take the most preferred option
  }
  
  
  int[] loadDistances(PathFinding mode, IVector target) { //returns a list of the "distances" of each direction from the target
    
    int[] distances; //array of the "distances" (the quotes will become apparent later)
    switch(mode) {
      case TOWARD: {
        IVector diff = IVector.add(body.tile,body.cDir).sub(target); //compute the difference between the future position and the target
        distances = new int[] {-diff.x,-diff.y,diff.x,diff.y};       //compute the NEGATIVE "distances" between where we'd be after moving in that direction AND the target tile
      } break;
      case AWAY: {
        IVector diff = IVector.add(body.tile,body.cDir).sub(target); //compute the difference between the future position and the target
        distances = new int[] {diff.x,diff.y,-diff.x,-diff.y};       //compute the "distances" between where we'd be after moving in that direction AND the target tile
      } break;
      case PATROL: {
        distances = new int[] {Integer.MIN_VALUE,0,Integer.MIN_VALUE,0}; //only vertical motion is acceptable
      } break;
      default: {
        distances = new int[4];               //initialize the distances array
        int randInd = (int)(4*Math.random()); //pick a random index between 0-3
        for(int n=0;n<4;n++) {                //now, loop through all indices
          distances[(randInd+n)&3] = 3-n;     //make the random direction our best option (weight 3), and make each direction clockwise to that slightly worse
        }
        //This is actually how it's done in Pac-Man, according to the Dossier. The ghost picks a random direction, then if that direction doesn't work, it turns 90 clockwise until it does work.
        //If you'd like an implementation that's truly, uniformly random, please use the code below, which generates the array 0,1,2,3, but shuffled in a random order:
        
        /*int rand3 = (int)(24*Math.random()); //compute a random integer between [0,24) (the 3 in the name will become apparent soon)
        int rand4 = rand3&3; rand3>>=2;      //divide by 4 and store the remainder
        int rand2 = rand3&1; rand3>>=1;      //divide by 2 and store the remainder. Now we have a random between [0,4), [0,3), and [0,2)
        if(rand3>=rand4) { ++rand3; }                               //perform range shifting on rand3
        if(rand2>=rand4) { ++rand2; } if(rand2>=rand3) { ++rand2; } //perform range shifting on rand2
        distances = new int[] {rand4, rand3, rand2, 6-rand4-rand3-rand2}; //now, "distances" is simply a list of 4 distinct, random integers between 0 and 3 inclusive*/
      }
    }
    //Now to explain what's going on with the "distances". First, it's actually easier to compute square distances, and squaring all elements won't change their ordering.
    //So, now each element holds the square distances, ||pos+dir-target||^2, or ||p+d-t||^2, or |p-t|^2+2d.(p-t)+|d|^2. d is a unit vector, so |d|^2 = 1. Likewise, if we subtract a
    //constant from each element, it won't change ordering. Since d is the only variable, |p-t|^2+1 is a constant, and can be subtracted from |p-t|^2+2d.(p-t)+1 to yield 2d.(p-t).
    //If we divide each element by 2, it still won't change the ordering, so we can just have each element be d.(p-t). Since d is always a positive or negative x or y unit vector,
    //this always reduces to either the positive or negative x or y coordinate. Thus, we can just pretend these are the distances and get away with it. In a sense, instead of
    //measuring distance, we're measuring how parallel each direction is to the line to our target, which is an equally valid measure.
    
    return distances; //return the resulting array
  }
  
  
  
  @Override
  public String toString() {
    String result = "Body: "+body.name+", Behavior: "+behavior+", Targetter: "+targetter;
    return result;
  }
}

void giveBrain(Actor a) {
  if     (a instanceof   Pac) { new Brain(a, Behavior.SCATTER);                           }
  else if(a instanceof Ghost) { new Brain(a, UpdateManager.getCorrectBehavior((Ghost)a)); }
}
