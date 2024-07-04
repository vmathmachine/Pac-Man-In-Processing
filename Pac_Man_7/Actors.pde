/////////////////////////////////////////////////////////////////////////////////// ACTORS ///////////////////////////////////////////////////////////////////////////////////

public static abstract class Actor {
  
  ///////////////////// ATTRIBUTES ///////////////////
  
  //basic attributes
  String name;                //character name
  Maze maze;                  //maze this actor lives in
  Game game;                  //game this actor and its maze lives in
  State state = State.NORMAL; //current existential state (either normal, vulnerable, eaten, big, dying, or dead)
  
  //positional attributes
  IVector tile=new IVector();  //tile position (determines hitbox)
  PVector atom=new PVector();  //atomic position (of center, determines how fast to move to the next pixel on the screen)
  
  IVector tilePrev=new IVector(); //previous tile position
  PVector atomPrev=new PVector(); //previous atomic position
  
  //other euclidean attributes
  float modX=0.5, modY=0.5; //where atom should be in a tile when "aligned" (0=far left/top, 1=far right/bottom, 0.5=middle of tile)
  
  //motion-based attributes
  IVector cDir=new IVector(), nDir=new IVector(); //current direction, previous direction (cDir says which way to look & try to go, nDir is where we want to go next)
  IVector pDir=new IVector();                     //previous direction (used solely for animation purposes, might be deleted soon)
  boolean corners;                                //whether this actor can corner
  boolean didCenter = true;                       //whether this actor reached the center before moving in the next direction (only applies to non-cornering actors)
  boolean changedDirection = false;               //whether this actor has changed direction at some time before centering
  boolean reverse = false;                        //an override feature: when true, the game forces the player to turn around the moment they enter the next tile
  short stopTimer = 0;                            //Forces the actor to stop in one place (when not 0). It decrements every frame that it's not 0
  
  Brain brain; //the brain (AI) that controls the Actor. Set to null if you want it to be controlled by a player (or if you just don't want it to move)
  
  //byte speedCheckMode = 0; //a special (RARELY USED) variable used to determine how we find speed. 0: normal playing, 1: intro
  float speedOverwrite = Float.NaN; //a variable to overwrite the speed, usually during cutscenes. When NaN, no overwrite occurs
  boolean caught = false;           //used only for animations. When true, the actor animates at 1/4 speed
  
  ///////////////////// CONSTRUCTORS ///////////////////
  
  public Actor() { } //default constructor
  
  public Actor(String names, Maze par, PVector p) { //general constructor
    name=names;     //assign name
    setParent(par); //assign parent
    atom=p;         //assign pixel position of the center
    
    wrapAround(); updatePos(); //correct the position on the torus
    tilePrev = tile.clone();   //set previous tile to current tile (because why not?)
  }
  
  public void destroy() { //a less dangerous version of finalize
    setParent(null);               //remove from its parent
    Artist.animation.remove(this); //remove from the animation hashmap
  }
  
  ////////////////// GETTERS/SETTERS /////////////////
  
  Actor setParent(Maze m) {
    if(maze!=null) { maze.remove(this); } //if the previous parent exists, have it disown this
    
    if(m!=null) { game = m.game; m.add(this); } //if the new parent exists, have it adopt this and set the enclosing game
    else        { game = null;                } //otherwise, set the enclosing game to null
    
    maze = m;    //set the parent maze
    return this; //return result
  }
  
  public Actor setPos(PVector v) { atom=v.copy(); /*atomPrev=v.copy();*/ wrapAround(); updatePos(); tilePrev.set(tile); return this; } //set position
  public Actor setPos(float x, float y) { return setPos(new PVector(x,y)); }
  
  public Actor setModX(float m) { modX=m; wrapAround(); updatePos(); return this; }
  public Actor setModY(float m) { modY=m; wrapAround(); updatePos(); return this; }
  
  ////////////////// MOVEMENT ON THE TORUS //////////////////////////
  //the entire maze is homeomorphic to a torus, thus when you go too far left/right/up/down, you'll end up on the right/left/bottom/top.
  //moreover, the tile position is discrete and must remain synced to the atomic position
  
  void wrapAround() { //ensure position wraps around
    atom.set(modPos(atom.x,maze.cell*maze.w), modPos(atom.y,maze.cell*maze.h)); //modulo position w/ width & height of maze
  }
  
  void updatePos() { //updates tile based on atom
    updatePos(maze.cell); //simply use the cell dimensions as a basis
  }
  
  void updatePos(int cell) {
    tile.set(atom.copy().div(cell).sub(modX,modY)); //divide by cell size, shift by half a tile (or whatever the mod is), cast to ivector
  }
  
  void move(float speed) { //<>//
    
    PVector target = closestMIM(atom,maze.cell,modX,modY); //our target location: the closest tile-aligned position to our current position
    
    if(!stopCollision(cDir) && (corners || didCenter || pDir.equals(cDir))) { //we can continue moving in our current trajectory if: doing so would not cause a collision AND (we are aligned to the center of the tile or can corner or are moving in a straight line)
      target.add(cDir.toPVector().mult(maze.cell));     //if so, increment our target location by our current direction
    }
    nudge(atom,target,speed); //finally, nudge ourselves closer to that target position
    //Originally, didCenter was instead cDir.cross(atom.copy().sub(target))==0, but didCenter replaced it because this expression does not account for turning around
    
    wrapAround();    //modulo position so it wraps around
    updatePos();     //updates tile position based on atomic position
  }
  
  void move() { //moves without a given speed
    move(findSpeed()); //just calculate what speed you're supposed to have, then move with that speed
  }
  
  void manageCenteringRecord() { //manage whether or not "didCenter" is true
    didCenter &= tile.equals(tilePrev);                                                                  //only stays true as long as you're in the same tile
    didCenter |= ((atom.x-maze.cell*modX) % maze.cell == 0 && (atom.y-maze.cell*modY) % maze.cell == 0); //but becomes true once we're in the middle of the tile
  }
  
  //////////////////////////////// NAVIGATION ////////////////////////////////////
  
  void setPreviousDirection() { pDir.set(cDir); } //sets the previous direction
  
  void setCurrentDirection() { //sets the current direction ONLY if all the conditions are right
    boolean changed = !tile.equals(tilePrev); //whether or not the tile changed
    
    if(changed && reverse) {         //if we have to reverse immediately:
      pDir.set(cDir); cDir.neg();    //set the previous direciton, then negate the current direction
      reverse=false; didCenter=true; //disable reverse, then pretend we've already centered
    }
    else if(!stopCollision(nDir) && (brain==null || changed)) { //2 conditions: no collision, and we just switched tiles (2nd requirement not needed for player characters)
      pDir.set(cDir); cDir.set(nDir);                           //if all tests are passed, change our current direction to our "next" direction (and record our previous direction)
    }
    //else if(changed) { nDir.set(cDir); } //otherwise, if we just switched tiles, we should cancel our next direction. Note, disabling this makes controls less authentic but more smooth
  }
  
  void setNextDirection() {
    if(brain != null && !tile.equals(tilePrev)) { //if we have a brain, and we just changed tiles:
      brain.setNextDirection(IVector.add(tile,cDir)); //use our brain to set our next direction (thinking about where we're about to be)
    }
  }
  
  void emergencyChangeCourse() { //in the case of an emergency, it changes the course (an emergency, in this case, meaning an actor has stopped completely and can't continue moving)
    if(brain == null) { return; } //in the case 
    
    if(stopTimer!=0 && atom.equals(atomPrev) && stopCollision(cDir)) { //if we're not intentionally stopping, we're not moving, and there's a wall right in front of us
      brain.setNextDirection(tile.copy()); //set the next direction
      pDir.set(cDir); cDir.set(nDir);      //now, set the previous & current direction
      
      println(name+" swerved");            //alert me that a swerve just occurred so I can bug test it if applicable
    }
    //this is an emergency manneuver, like a swerve, since instead of predicting where to go 1 tile from now, then moving there when we get there, we immediately choose where to go and go there
  }
  
  void stop(int s) { stopTimer = (short)s; } //makes the actor stop for s frames
  
  void stop()      { stop(-1);             } //makes the actor stop until we tell it to not stop
  void unstop()    { stop(0);              } //unfreezes the actor by setting their stop timer to 0
  
  ///////////////////////////////// COLLISION /////////////////////////////////
  
  boolean stopCollision(IVector dir) { //prevent collisions before they occur (returns true if we have to stop moving to prevent a collision)
    return willCollide(tile, dir, false);     //plug in our current tile position as the initial position, then return whether or not we will collide should we move in this direction
  }
  
  boolean willCollide(IVector init, IVector dir, boolean ai) { //returns whether or not a collision will occur given an initial position and direction
    IVector tileNext = IVector.add(init,dir).mod(maze.w,maze.h); //compute the next tile we'd be at
    if(canPass(maze.get(tileNext),ai)) { return false; }         //if this is a special surface that we can pass no matter what, return false (cuz there's no collision)
    
    if(dir.equals( 1, 0)) { return maze.get(tileNext). left(); } //left hitbox
    if(dir.equals( 0, 1)) { return maze.get(tileNext).   up(); } //top hitbox
    if(dir.equals(-1, 0)) { return maze.get(tileNext).right(); } //right hitbox
    if(dir.equals( 0,-1)) { return maze.get(tileNext). down(); } //bottom hitbox
    return false; //no hitbox: return false
  }
  
  abstract boolean canPass(Grid gr, boolean ai); //whether you can pass right through boundaries of this type (results vary depending on if using the AI)
  
  ///////////////////////// MORE GEOMETRY & MOTION //////////////////////////
  
  public abstract float findSpeed(); //returns the appropriate speed given all current conditions
  
  boolean inTunnel() { return maze.tunnel.hitbox(tile); } //returns whether or not it's in the tunnel(s)
  
  ////////////////// DISPLAYING ////////////////////////
  
  void basicDisplay(final PGraphics g) { //basic display for without sprites
    switch(name) {
      case "Pac-Man": g.fill(#FFFF00); break;
      case "Blinky" : g.fill(#FF0000); break;
      case "Pinky"  : g.fill(#FFAAFF); break;
      case "Inky"   : g.fill(#00FFFF); break;
      case "Clyde"  : g.fill(#FFAA55); break;
    }
    g.rect(round(maze.cx+atom.x-maze.cell),round(maze.cy+atom.y-maze.cell),2*maze.cell,2*maze.cell);
  }
  
  /////////////////// UPDATES ////////////////////////
  
  void progress1Frame() { //progress 1 frame
    //manageCenteringRecord(); //manage whether it needs to center
    setCurrentDirection();   //set the current direction
    setNextDirection();      //set the next direction
    move();                  //move appropriately
    wrapAround();            //modulo position so it wraps around
    updatePos();             //update tile position based on atomic position
    
    emergencyChangeCourse(); //if an emergency arises, change course
  }
  
  void update() {
    if(stopTimer!=0) { --stopTimer; return; } //if the stop timer ISN'T 0, decrement it. Otherwise, continue updating
    
    PVector atom2 = atom.copy();
    IVector tile2 = tile.copy(); //record the original values of atom & tile
    
    progress1Frame(); //progress 1 frame
    
    atomPrev = atom2;
    tilePrev = tile2; //set the previous values for atom & tile
    
    manageCenteringRecord(); //manage whether or not it needs to center next frame
  }
  
  void setState(final State s) {
    if(state == s) { return; } //no difference: change nothing
    
    state = s; //set the state
    if(brain != null && this instanceof Ghost && brain.behavior.canChange()) { //if it has a brain, it's a ghost, and the brain's behavior can change
      
      Behavior behavior;
      try { behavior = UpdateManager.getCorrectBehavior((Ghost)this); } //obtain the CORRECT behavior (or at least try to)
      catch(RuntimeException ex) { behavior = null; }                   //but if you obtain an invalid behavior, set it to null
      
      if(behavior!=null) { brain.setBehavior(behavior); } //if the behavior ISN'T invalid, set that behavior
      
    }
  }
  
  
  //////////////////////////// OTHER /////////////////////////////////////
  
  
  @Override
  public String toString() {
    String result = name+":\n";                                                            //Start with the name
    result += "Position: <"+atom.x+", "+atom.y+"> (<"+tile.x+", "+tile.y+">)\n"+                          //list positions
              "Velocities: <"+cDir.x+", "+cDir.y+">, <"+nDir.x+", "+nDir.y+">\n"+                         //velocities
              "Previous Position: <"+atomPrev.x+", "+atomPrev.y+"> (<"+tilePrev.x+", "+tilePrev.y+">)\n"+ //previous positions
              "State: "+state+", Class: "+getClass().getSimpleName()+", Modulos: "+modX+", "+modY+"\n"+   //state, class, modulos
              "can"+(corners?"":"not")+" corner, did"+(didCenter?"":"n't")+" center\n"+                   //can corner, did center
              "Brain = {"+brain+"}";                                                                      //has a brain (if so, what?)
    return result;
  }
}

/////////////////////////////////////////////////////////////////////////////////// PAC ///////////////////////////////////////////////////////////////////////////////////

public static class Pac extends Actor { //a class for members of the Pac species
  
  Pac(String names, Maze par, PVector p) { //general constructor
    super(names, par, p);
  }
  
  @Override
  boolean canPass(Grid gr, boolean ai) { return gr.getBarrier() == Barrier.PASSAGEWAY; } //the only walls Pac-Man can pass through are passageways (there are 4 in the original Pac-Man)
  
  @Override
  float findSpeed() {
    if(speedOverwrite==speedOverwrite) { return speedOverwrite; } //if we have a speed overwrite, return the speed overwrite
    
    int lev = maze.levelMap; //find the effective level
    
    int index1 = lev==1 ? 0 : (lev<=4 || lev>20 ? 1 : 2); //find the first index of the array
    int index2 = maze.frightTimer==0 ? 0 : 1;             //find the second index of the array
    
    return 1.25 * game.values.pacSpeeds[index1][index2]; //use the table to look up the speed we go, then multiply by 1.25 px/frame (full speed)
  }
}

/////////////////////////////////////////////////////////////////////////////////// GHOSTS ///////////////////////////////////////////////////////////////////////////////////

public static class Ghost extends Actor { //a class for ghosts
  
  public int dotCounter = 0; //Each ghost has its own dot counter. Only one dot counter can increment at a time, and once the dot counter reaches a certain amount, the ghost may leave the ghost house
  
  Ghost(String names, Maze par, PVector p) { //general constructor
    super(names, par, p);
  }
  
  @Override
  boolean canPass(Grid gr, boolean ai) { //the only walls Ghosts can pass through are gates (sometimes) and passageways (sometimes)
    return gr.getBarrier() == Barrier.GATE && (!ai || modX==0) /*&& abs(atom.x-128)<4*/ && (!ai || brain.behavior!=Behavior.BASE_PATROL) || //gate
           gr.getBarrier()==Barrier.PASSAGEWAY && (!ai || state!=State.NORMAL);                                                             //barrier
  }
  
  @Override
  float findSpeed() {
    if(speedOverwrite==speedOverwrite) { return speedOverwrite; } //if we have a speed overwrite, return the speed overwrite
    /*if(speedCheckMode==1) { return state==State.VULNERABLE ? 0.5*1.25 : 0.85*1.25; } //special case: intro, go at 85% or 50% speed
    else if(speedCheckMode==2) { return state==State.VULNERABLE ? 0.75 : 1.3125; }
    else if(speedCheckMode==3) { return 1.3125; }*/ //TODO delete this
    
    int lev = maze.levelMap; //find the effective level
    
    if(brain!=null && brain.behavior.isBase()) { return 1.25*0.4; } //in base: 40% speed
    
    //if(ai!=null && ai.state==State.exit) { return 0.435; } //while leaving the base, ghosts travel slightly slower
    
    if(state == State.EATEN) { return 2.5; } //ghosts go at their fastest speed while running to the ghost house
    
    if(isElroy() && !inTunnel()) { //if this is blinky as cruise elroy (and he's NOT in a tunnel):
      return findElroySpeed(lev);  //compute the Elroy speed, then return it
    }
    
    int index1 = lev==1 ? 0 : (lev<=4 ? 1 : 2);                      //the first index of the array
    int index2 = inTunnel() ? 1 : (state==State.VULNERABLE ? 2 : 0); //the second index of the array
    
    return 1.25 * game.values.ghostSpeeds[index1][index2]; //use the table to look up the speed we go, then multiply by 1.25 px/frame (full speed)
  }
  
  
  @Override
  void update() {
    super.update(); //perform the already implemented update functionality
    
    //now, we just have to fix alignment depending on if we're entering/leaving the ghost house
    manageGhostHouseAlignment(); //manages ghost house alignment
  }
  
  //TODO make this reusable
  void manageGhostHouseAlignment() { //manages the behavior in the ghost house, ensuring the ghost is always correctly aligned
    //entering the ghost house:
    if     (modX==0.5 && tile.equals(15,11) && nDir.equals(0,1)) { setModX(0); didCenter=true; }
    else if(modY==0.5 && tile.equals(16,12) && nDir.equals(0,1)) { setModY(0); didCenter=true; }
    
    //exiting the ghost house:
    if     (modX==0 && atom.y==92 && tile.x==16 && !nDir.equals(0,1)) { setModX(0.5); didCenter=true; }
    else if(modY==0 && tile.y==12 && tile.x==16 && !nDir.equals(0,1)) { setModY(0.5); didCenter=true; }
    
    if(modX==0.5 && tile.equals(16,11) && nDir.equals(0,1)) { atom.x-=0.0625; setModX(0); didCenter=false; }
    //HACK, BUG
    //when in a certain position, we force the ghost to align properly. The bug is, sometimes, it still doesn't work :/
  }
  
  /////////////// CRUISE ELROY MODE /////////////////////////
  
  boolean isElroy() { //returns whether or not this Ghost is Blinky and he's in Cruise Elroy mode
    int level = maze.levelMap; //find the effective level count
    
    return name.equals("Blinky") && state==State.NORMAL && maze.dotsLeft <= game.values.elroyDots1(level) && //first, make sure it's blinky, normal, and there's less than a certain # of dots left
           (maze.get("Clyde").brain==null || maze.get("Clyde").brain.behavior!=Behavior.BASE_PATROL);        //next, make sure that clyde is OUTSIDE the base. or if he's in the base, he's ready to leave
  }
  
  float findElroySpeed(final int lev) { //find the speed, assuming we're in Cruise Elroy mode
    //when in elroy mode, we essentially just go the same speed as Pac-Man, but with some modifications
    
    int index1 = lev==1 ? 0 : (lev<=4 || lev>20 ? 1 : 2); //find the first index of the array
    int index2 = maze.frightTimer==0 ? 0 : 1;           //find the second index of the array
    float speed = 1.25 * game.values.pacSpeeds[index1][index2]; //compute Pac-Man's speed
    
    if(lev>=21) { speed = 1.25; } //after level 20, Pac-Man slows down a bit, but Elroy speed stays the same
    
    if(maze.dotsLeft > game.values.elroyDots2(lev)) { return speed;             } //when in the first stage of cruise elroy, return that exact speed
    else                                            { return speed + 0.05*1.25; } //when in the second stage, return that speed but with a 5% increase
  }
}

/////////////////////////////////////////////////////////////////////////////////// FRUITS ///////////////////////////////////////////////////////////////////////////////////

public static class Fruit extends Actor {
  public short timer = 0; //how long until the fruit should disappear
  
  Fruit(String names, Maze par, PVector p) {
    super(names, par, p); modX = 0;
  }
  
  
  @Override
  void move() { } //fruit don't move
  
  @Override
  float findSpeed() { return 0; } //fruit don't have speeds
  
  @Override
  boolean canPass(Grid gr, boolean ai) { return false; } //fruit don't have collision
  
  @Override
  void update() {
    if(timer!=0) { //if there's time left:
      --timer;     //decrement the timer
      if(timer==0) { //if time just ran out:
        setState(State.INVISIBLE); //make it disappear
      }
    }
  }
}
