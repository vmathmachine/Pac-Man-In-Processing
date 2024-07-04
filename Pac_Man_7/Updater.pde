public static class UpdateManager { //used for, you guessed it, managing updates
  
  /////////////////////////// UPDATE WRAPPERS ///////////////////////////
  
  public static void updateGame(Game game) {
    if(!game.isPausedCompletely && game.mode.canUpdate()) { //if the game isn't paused, and it's in a mode where it's appropriate to update:
      boolean sounds = (game.screen == Screen.NORMAL);      //determine if we can play sounds
      UpdateManager.updateMaze(game.maze, sounds);          //udpate the maze
      
      game.updateScoreCache();                              //update the scores we display
    }
  }
  
  public static void updateMaze(Maze maze, boolean sounds) {
    //pre-update stuff:
    int scorePrev = maze.score; //record the score before the update
    
    //rack test:
    if(maze.game.rackTest && maze.game.screen!=Screen.START_SCREEN && maze.game.screen!=Screen.CREDIT_SCREEN && !maze.game.screen.isCutscene()) { //if the rack test cheat is on (and we're not on the start screen):
      maze.clearDots(); //remove all the dots from the maze
      respondToMazeCompletion(maze.game); //respond to maze completion
      return;                             //IMMEDIATELY quit, there are no more updates to make!
    }
    
    //update all the actors
    for(Actor actor : maze) { //loop through all actors
      actor.update();         //update all actors
    }
    
    //then, after the initial updates, perform even MORE updates!
    for(Actor actor : maze) {
      if     (actor instanceof  Pac ) { moreUpdates(maze,( Pac )actor,sounds); } //updates specific to Pac creatures
      else if(actor instanceof Ghost) { moreUpdates(maze,(Ghost)actor,sounds); } //updates specific to Ghosts
    }
    
    //post-updates:
    manageBonusLives(maze, scorePrev, sounds); //manage the bonus-lives mechanism
    forceKickGhost(maze);                      //force kick ghosts after a certain time has expired
    
    manageTimers(maze);                        //manage all the maze's timers
    
    if(maze.dotsLeft==0) { respondToMazeCompletion(maze.game); } //respond to maze completion
  }
  
  ////////////////////////////// MORE UPDATES ////////////////////////////////////
  
  //each Actor gets a "moreUpdates" function, which performs extra updates that can only be performed after all actors have moved
  
  
  //for Pac creatures, this method simply updates everything the Pac just touched
  public static void moreUpdates(Maze maze, Pac pac, boolean sounds) { //more updates for the Pac creatures
    
    if     (maze.getItem(pac.tile) == Item.PAC_DOT  ) { eatPacDot   (maze,pac,pac.tile,sounds); } //pac dot: eat pac dot
    else if(maze.getItem(pac.tile) == Item.ENERGIZER) { eatEnergizer(maze,pac,pac.tile,sounds); } //energizer: eat energizer
    
    for(Actor actor : maze) { //loop through all other actors in this maze
      if(actor instanceof Pac) { continue; } //skip all Pac creatures
      
      if(actor.tile.equals(pac.tile)) { //if both actors are in the same tile:
        if(actor instanceof Fruit && actor.state != State.INVISIBLE && actor.state != State.EATEN) { //if the actor is a fruit (AND IT'S PRESENT):
          eatFruit((Fruit)actor, sounds);                         //eat the fruit
        }
        else if(actor instanceof Ghost && maze.game.dying==null) { //otherwise, if the actor is a ghost (and there aren't any ghosts animated dying):
          if(actor.state == State.VULNERABLE || pac.state == State.BIG) { //if the ghost is vulnerable (or the Pac is big, hehe):
            eatGhost(pac, (Ghost)actor, sounds); //eat the ghost
          }
          else if(!maze.invincible && actor.state == State.NORMAL /*&& pac.state!=State.DYING*/) { //if the ghost is normal:
            killPac(pac); //kill the Pac creature
          }
        }
      }
    }
  }
  
  //for Ghosts, this method performs some minor brain surgery, updating the ghost's behavior, then updates its state depending on its position
  public static void moreUpdates(Maze maze, Ghost ghost, boolean sounds) {
    
    //now, we have to do some minor brain surgery, make some updates whenever certain events happen
    if(ghost.brain!=null) { //first, make sure we even HAVE a brain
      Brain brain = ghost.brain; //load ghost's brain
      Behavior behavePrev;       //initial behavior
      do {
        behavePrev = brain.behavior; //record the initial behavior
        switch(brain.behavior) {     //switch the brain's behavior
          
          // NORMAL BEHAVIORS:
          
          case SCATTER: case CHASE: //scatter & chase mode:
            Behavior behavior = getCorrectBehavior(ghost); //find the current appropriate behavior
            if(behavior!=brain.behavior) { //if that's not the current behavior:
              ghost.reverse=true;          //make them turn around
              brain.setBehavior(behavior); //change their behavior
            }
          break;
          
          
          
          case EATEN: //if we're in eaten mode:
            //TODO make this more reusable
            if(ghost.tile.y==11 && abs(ghost.atom.x-128)<4) { //once we reach the base entrance:
              ghost.setModX(0); brain.setBehavior(Behavior.BASE_ENTER); ghost.cDir.set(0,1); ghost.nDir.set(0,1);
            }
          break;
          
          // BASE BEHAVIORS:
          
          case BASE_PATROL: //base patrol mode:
            if(Game_Values.shouldLeave(ghost)) {       //if the ghost should leave:
              brain.setBehavior(Behavior.BASE_EXIT_1); //make them leave
              ghost.nDir.set(sgn(16-ghost.tile.x),0); //TODO make this more reusable
            }
          break;
          
          case BASE_ENTER:
            IVector destination; //the tile the ghost much reach before they can go back to base patrol
            switch(ghost.name) { case "Blinky": case "Pinky": destination = new IVector(16,14); break;
                                 case "Inky":                 destination = new IVector(14,15); break;
                                 default:                     destination = new IVector(18,15); } //choose destination given ghost
            
            if(ghost.tile.equals(destination)) { //if the ghost has reached its destination:
              brain.setBehavior(Behavior.BASE_PATROL); //switch to base patrol behavior
              if(ghost.state==State.EATEN) {  //if the ghost state is EATEN (which it should be!!!):
                ghost.setState(State.NORMAL); //revert to the normal state
                if(ghost.game.mode==Mode.EAT_GHOST) { ghost.stop(ghost.game.timer); } //if currently in the EAT GHOST mode, make the ghost stop until that's no longer the case
              }
            }
            
          break;
          
          case BASE_EXIT_1: //if we're trying to get out,
            if(ghost.tile.x==16) { //and we finished the first phase:
              brain.setBehavior(Behavior.BASE_EXIT_2);
              ghost.cDir.set(0,-1); ghost.nDir.set(0,-1);
            }
          break;
          
          case BASE_EXIT_2: //if we're targetting the base's entrance,
            if(ghost.tile.equals(15,11)) { //and we're at the base's entrance:
              brain.setBehavior(getCorrectBehavior(ghost)); //set the correct behavior
            }
          break;
        }
      } while(brain.behavior != behavePrev); //loop until the behavior stops changing
    }
    
    if(ghost.brain==null && ghost.state==State.EATEN && maze.ghostHouse.hitbox(ghost.tile)) { //if the ghost is eaten, brainless, and in the ghost house:
      ghost.setState(State.NORMAL); //set the state to normal
      if(maze.game.mode==Mode.EAT_GHOST) { ghost.stop(maze.game.timer); } //if in pause-for-ghost-eating mode, stop until that's not the case
    }
  }
  
  /////////////////////////// EATING ///////////////////////////////
  
  public static void eatPacDot(Maze maze, Pac pac, IVector tile, boolean sounds) {
    eatAnyDot(maze, pac, tile, sounds); //eat the dot
    pac.stop(1);                        //make the Pac freeze for one frame
    ++maze.score;                       //increment the score
  }
  
  public static void eatEnergizer(Maze maze, Pac pac, IVector tile, boolean sounds) {
    eatAnyDot(maze,pac,tile,sounds); //eat the energizer
    pac.stop(5);                     //make the Pac freeze for 5 frames
    enableFright(maze);              //enable fright mode
    maze.score+=5;                   //increment the score by 5
  }
  
  public static void eatAnyDot(Maze maze, Pac pac, IVector tile, boolean sounds) {
    maze.setItem(tile, Item.NONE); //remove the item
    --maze.dotsLeft;               //decrement dot count
    if(maze.dotsLeft==70 || maze.dotsLeft==170) { //if there are either 70 or 170 dots left:
      addFruit(maze);                             //add a fruit to the maze
    }
    
    manageDotCounters(maze); //manage dot counters for the maze
    
    maze.timeSinceLastDot = 0; //reset the time since we last ate a Pac-Dot
    
    if(sounds) {
      if((maze.dotsLeft&1)==1) { DeeJay.waka1.stop(); DeeJay.waka1.play(); } //every other dot, we alternate between
      else                     { DeeJay.waka2.stop(); DeeJay.waka2.play(); } //two sounds
    }
  }
  
  public static void eatFruit(Fruit fruit, boolean sounds) {
    fruit.setState(State.EATEN); //swap the fruit to the eaten state
    fruit.timer = 60;            //set the fruit to disappear in 60 frames (1 second)
    
    int score = fruit.game.values.fruitPoints[fruit.game.values.fruitIndex(fruit.maze.level)]; //compute how many points this fruit is worth
    fruit.maze.score += score; //increment the score
    
    if(sounds) { DeeJay.eatFruit.stop(); DeeJay.eatFruit.play(); } //if you can, play the sound of eating fruit
  }
  
  //////////////////////// FRIGHT MODE RELATED ////////////////////////////
  
  public static void enableFright(Maze maze) { //enables fright mode
    int lev = maze.levelMap; //compute the effective level
    if(lev > 19) { lev=19; } //all levels 19+ act the same, in terms of fright mode
    
    maze.frightTimer = round(60*maze.game.values.frightDuration[lev-1]); //start fright mode and set it to last for a duration we can find in a table
    
    maze.comboCount = 0; //reset the number of consecutive ghosts eaten back to 0
    for(Actor ghost : maze) { if(ghost instanceof Ghost && ghost.state!=State.INVISIBLE) { //loop through all the ghosts
      frightenGhost((Ghost)ghost);                                                    //frighten each ghost
    } }
    
    if(maze.game.screen == Screen.START_SCREEN) {
      for(Actor actor : maze) { actor.reverse = true; actor.nDir.neg(); if(actor instanceof Ghost) { actor.speedOverwrite=0.5*1.25; } }
    }
  }
  
  public static void frightenGhost(Ghost ghost) { //activates fright mode for a single ghost
    if(ghost.state == State.NORMAL) {   //first, make sure the ghost is normal
      ghost.setState(State.VULNERABLE); //if so, set state to vulnerable
    }
    if(!(ghost.brain==null || !ghost.brain.behavior.canChange())) { //unless the ghost is brainless or unable to change states:
      ghost.reverse = true;                                         //force them to turn around
    }
    
    Artist.animation.put(ghost, Artist.animation.get(ghost)&15); //adjust the ghost's animation
  }
  
  public static void disableFright(Maze maze) { //disables fright mode
    for(Actor ghost : maze) { if(ghost instanceof Ghost) { //loop through all the ghosts
      if(ghost.state == State.VULNERABLE) { //first, make sure the ghost is vulnerable (as opposed to normal or eaten)
        ghost.setState(State.NORMAL);                                //THIS IS A VERY RUDIMENTARY WAY TO MAKE THEM NORMAL, IT IS NOT COMPLETED!!!!
        Artist.animation.put(ghost, Artist.animation.get(ghost)&15); //adjust the animation
        //TODO this
      }
    } }
  }
  
  ///////////////////// DOT COUNTER UPDATES ////////////////////////
  
  public static void manageDotCounters(Maze maze) { //updates the dot counters right after a dot was eaten
    if(maze.doGlobalDotCounter) {   //if we're using the global dot counter to release ghosts:
      manageGlobalDotCounter(maze); //manage global dot counter
    }
    else {                            //otherwise, we're using each ghost's individual dot counter
      managePersonalDotCounter(maze); //manage the local dot counters
    }
  }
  
  public static void manageGlobalDotCounter(Maze maze) { //updates the global dot counter right after a dot was eaten
    ++maze.globalDotCounter;        //increment the global dot counter
    if(maze.globalDotCounter==32) { //once the dot counter reaches 32:
      Ghost clyde = (Ghost)maze.get("Clyde"); //grab Clyde
      if(clyde.brain==null || clyde.brain.behavior==Behavior.BASE_PATROL) { //if Clyde is either brainless or on patrol at this time:
        maze.doGlobalDotCounter=false;                                      //disable the global dot counter
      }
    }
  }
  
  public static void managePersonalDotCounter(Maze maze) { //updates the global dot counters right after a dot was eaten
    Ghost[] ghosts = {(Ghost)maze.get("Blinky"),(Ghost)maze.get("Pinky"),(Ghost)maze.get("Inky"),(Ghost)maze.get("Clyde")};
    
    for(Ghost ghost : ghosts) { //loop through all ghosts
      if(ghost.brain!=null && ghost.brain.behavior == Behavior.BASE_PATROL) { //if they are patrolling the base:
        ++ghost.dotCounter; //increment the dot counter
        break;              //quit the loop
      }
    }
  }
  
  //////////////////// GAME MODE CHANGING ///////////////////////////////
  
  public static void killPac(Pac pac) { //initialize killing a Pac creatured
    pac.game.mode = Mode.PAC_DEATH_1; //first, swap to pac death mode
    pac.game.timer = 80;              //move to the next stage of his death in 80 frames
    pac.game.dying = pac;             //update it so we know this is the character who's dying right now
    for(Actor actor : pac.maze) {
      actor.stop(80);                 //make them all stop for 80 frames
      actor.atomPrev.set(actor.atom); //make your position and previous position the same
    }
  }
  
  public static void eatGhost(Pac pac, Ghost ghost, boolean sound) { //initialize a Pac creature eating a ghost
    ++pac.maze.comboCount;                       //increment the combo count
    pac.maze.score += 10 << pac.maze.comboCount; //increment the score
    
    pac.game.mode = Mode.EAT_GHOST;       //first, swap to eating ghost mode
    pac.game.timer = 56;                  //prepare to stop the pause in 56 frames
    
    if(sound) { DeeJay.eatGhost.stop(); DeeJay.eatGhost.play(); }
    
    pac.setState(State.INVISIBLE); ghost.setState(State.INVISIBLE); //make both the pac creature and the eaten ghost temporarily invisible
    pac.game.eater = pac; ghost.game.dying = ghost;                 //set the eater and the dying ghost
    
    for(Actor actor : pac.maze) { //loop through all actors in the maze
      if(actor.state != State.EATEN) { actor.stop(56); } //make them all stop for 56 frames (except the eaten ones)
    }
  }
  
  public static void respondToMazeCompletion(Game game) {
    game.mode = Mode.MAZE_FINISHED_1; //switch to flashing maze mode
    game.timer = 128;                 //schedule to move on to the next stage of maze completion in 128 frames
  }
  
  public static void incrementLevel(PApplet app, Maze maze) {
    maze.setLevel(maze.level+1);                                         //increment the level
    if(maze.game.mazes.length!=0) { maze.game.levelCache = maze.level; } //update the level cache (unless in demo mode) (AGAIN, THIS IS A VERY HAPHAZARD WAY OF SEEING IF WE'RE IN DEMO MODE)
    
    maze.dotsLeft = 244;         //reset the number of dots left to 244 (should probably be done somewhere else???)
    //TODO move the above line /|\ somewhere else
    
    if((maze.level&255) == 0) { maze.loadMaze(app.createReader("assets"+dirChar+"maze file 256.txt")); } //level 256: load level 256
    else                      { maze.loadMaze(app.createReader("assets"+dirChar+"maze file.txt"    )); } //every other level: load the normal levels
  }
  
  ////////////////////////// OTHER UPDATES ////////////////////////////////
  
  public static void addFruit(Maze maze) {
    Fruit fruit = (Fruit)maze.get("Fruit"); //grab the fruit
    fruit.setState(State.NORMAL);           //make it visible
    fruit.timer = 570;                      //prepare for it to disappear in 9.5 seconds
  }
  
  public static Behavior getCorrectBehavior(Ghost ghost) { //returns the correct current behavior of the ghost, ASSUMING they're not currently in the ghost base
    switch(ghost.state) { //switch their current state
      case NORMAL:     //normal mode: either scatter or chase
        return ghost.game.values.getBehavior(ghost.maze.levelMap, ghost.maze.levelTimer); //return the behavior, given the level & level timer
      case VULNERABLE: //vulnerable mode:
        return Behavior.FRIGHTENED; //frightened mode
      case EATEN:      //eaten mode
        return Behavior.EATEN; //eaten mode
      default:
        throw new RuntimeException("Improper case label: You shouldn't analyze the behavior when a ghost is in the mode \""+ghost.state+"\""); //throw an exception for the wrong case
    }
  }
  
  
  public static void manageTimers(final Maze maze) { //manages all the maze's timers
    if(maze.game.mode != Mode.NORMAL) { return; }  //special case, game mode is not normal: even though the game updates, the timers freeze
    
    if(maze.frightTimer==0) { //if not in fright mode:
      ++maze.levelTimer;      //increment the level timer
    }
    else {                  //if fright mode isn't over yet:
      --maze.frightTimer;     //decrement the fright timer
      if(maze.frightTimer==0) { //if it just ended
        disableFright(maze);    //disable fright mode
      }
    }
    
    ++maze.timeSinceLastDot; //increment the amount of frames that have passed since the last dot was eaten
  }
  
  public static void forceKickGhost(Maze maze) { //implements the behavior that force-kicks a ghost after a certain amount of time has passed since the last dot was eaten
    if(maze.game.screen == Screen.START_SCREEN || maze.game.screen == Screen.CREDIT_SCREEN || maze.game.screen.isCutscene()) { return; } //ignore during start screen
    
    int index = maze.levelMap <=4 ? 0 : 1; //levels 1-4 map to index 0, levels 5+ map to index 1
    
    if(maze.timeSinceLastDot >= maze.game.values.ghostKickTime[index]) { //if the time passed is at least as much as the specified number:
      Actor[] ghosts = {maze.get("Pinky"), maze.get("Inky"), maze.get("Clyde")};
      
      for(Actor actor : ghosts) { //loop through all 3 of the ghosts
        if(actor.brain!=null && actor.brain.behavior == Behavior.BASE_PATROL) { //if the ghost is patrolling the base:
          //if(actor.name.equals("Pinky")) { println("I'M SO SORRY PINKY!"); }
          actor.brain.setBehavior(Behavior.BASE_EXIT_1);
          
          maze.timeSinceLastDot = 0; //reset the counter so that it doesn't immediately kick out the next ghost
          return;                    //force quit the function
        }
      }
    }
  }
  
  public static void manageBonusLives(final Maze maze, final int scorePrev, final boolean sounds) {
    if(maze.score >= maze.game.scoreForOneUp && scorePrev < maze.game.scoreForOneUp) { //if we JUST got enough points for a 1-UP:
      maze.incrementLives(); //increment the number of lives
      //TODO figure out if this also applies for Pac-Man in the demo screen. That'd be crazy AND interesting if it did
      
      if(sounds) { //if sounds are enabled
        DeeJay.oneUp.stop(); DeeJay.oneUp.play(); //play the one-up sound
      }
    }
  }
}
