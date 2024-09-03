public static class Choreographer { //choreographs animations during certain screens, such as the start up screen and the 3 intermissions
  
  
  public static void changeGameMode(Game game, PApplet app, boolean sound) { //changes the game's mode ASSUMING IT NEEDS TO BE CHANGED (aka, timer is 0)
    switch(game.mode) { //switch the game mode
      case INTRO: {               //INTRODUCTION
        for(Actor actor : game.maze) if(!(actor instanceof Fruit)) { //loop through all (non-fruit) actors
          actor.setState(State.NORMAL);                              //make them all visible
        }
        
        game.maze.decrementLives(); //decrement the number of lives
        
        game.mode = Mode.READY; //swap from intro to ready
        game.timer = 128;       //schedule a change to normal in 128 frames
      } break;
      
      case READY: { //READY
        game.mode = Mode.NORMAL; //swap from ready to normal
        game.timer = -1;         //schedule infinite timer
        
        if(game.screen == Screen.START_SCREEN) { //on the start screen:
          game.choreoTimer=596;
        }
      } break;
      
      case NORMAL: { println("AAAAAAAAAAH! THE TIMER WAS 0 IN NORMAL MODE!!!"); //in any other case, be sure to yell at me
      //TODO: remove this case once you're sure this problem can't occur
      } break;
      
      
      case PAC_DEATH_1: { //PAC MAN DEATH: STAGE 1
        for(Actor actor : game.maze) { actor.setState(State.INVISIBLE); } //make all actors invisible (including the fruit)
        game.dying.setState(State.DYING);                                 //exception: the dying Pac creature, animate them dying
        
        if(sound) { DeeJay.deathSound.stop(); DeeJay.deathSound.play(); } //if permitted, play the death sound
        Artist.animation.put(game.dying,-1);                              //initialize the death animation to -1 (because after this, we'll increment the animation, and we want the first frame we see of this to be frame 0)
        
        game.mode = Mode.PAC_DEATH_2; //swap from stage 1 to stage 2
        game.timer = 88;              //schedule a change to stage 3 in 88 frames
      } break;
      
      case PAC_DEATH_2: { //PAC MAN DEATH: STAGE 2
        game.dying.setState(State.INVISIBLE); //make the dying Pac creature invisible
        
        game.mode = Mode.PAC_DEATH_3; //swap from stage 2 to stage 3
        game.timer = 16;              //schedule a change to ready/game over in 16 frames
      } break;
      
      case PAC_DEATH_3: { //PAC MAN DEATH: STAGE 3
        
        game.maze.decrementLives(); //decrement life count
        
        if(game.maze.lives==0) {  //if we've run out of lives:
          --game.activePlayers;   //decrement the number of active players
          if(game.activePlayers==0) {   //if we run out of active players:
            game.mode = Mode.GAME_OVER; //go into GAME OVER mode
          }
          else { //otherwise:
            game.mode = Mode.TEMP_GAME_OVER; //go into TEMPORARY game over mode, causing us to say which player has game overed then switch to the next player still in the game
          }
          game.timer = 150;          //schedule a transition after 150 frames
          Artist.energizerClock = 0; //make the energizers visible
          //TODO see if this is necessary /|\
          return;
          //after that, break so that we can wait until AFTER the game over pause to switch players
        }
        
        Game.resetMaze(game.maze, true); //reset the maze back to its default configuration (without resetting items)
        
        if(game.player1!=null) { game.player1.brain = null; }
        if(game.player2!=null) { game.player2.brain = null; }
        game.cycleMazes();      //cycle between mazes (in case there's more than one player)
        
        game.mode = Mode.READY; //swap from pac-man death to ready mode
        game.timer = 60;        //schedule the level to start again in 60 frames
      } break;
      
      
      
      
      case EAT_GHOST: {
        game.eater.setState(State.NORMAL); //make the Pac creature visible again
        if(game.screen == Screen.START_SCREEN) { game.dying.setState(State.INVISIBLE); } //on the start screen, eaten ghosts disappear
        else                                   { game.dying.setState(State.EATEN);     } //in every other state, they swap into eaten mode (trying to get back to base)
        
        Artist.animation.put(game.eater,0); Artist.animation.put(game.dying,0); //reset both of their animations
        game.dying = game.eater = null;                                         //set both of them back to null
        
        game.mode = Mode.NORMAL; //swap back into normal mode
        game.timer = -1;         //schedule infinite timer
      } break;
      
      
      
      case MAZE_FINISHED_1: {
        for(Actor ghost : game.maze) { if(ghost instanceof Ghost) { ghost.setState(State.INVISIBLE); } } //make all ghosts invisible
        
        game.mode = Mode.MAZE_FINISHED_2; //swap from stage 1 to stage 2
        game.timer = 128;                 //schedule level ending in 128 frames
      } break;
      
      case MAZE_FINISHED_2: {
        
        switch(game.maze.level) { //Right after certain levels, we show a cutscene
          case 2: {
            //TODO move this code to somewhere more appropriate
            game.screen = Screen.CUTSCENE_1; //after level 2, move to cutscene 1
            game.choreoTimer = 278;          //schedule for the cutscene to end after 660 frames
            
            game.tempMaze = game.maze; //store a shallow copy of the current maze
            game.maze = new Maze(-96,24,70,32,8,true);
            game.maze.game = game;
            game.maze.tunnel = new Hitbox() { public boolean hitbox(IVector v) { return false; } };
            
            Pac pac = (Pac)new Pac("Pac-Man",game.maze,new PVector(353,136)).setModY(0); pac.cDir.set(-1,0); pac.nDir.set(-1,0); pac.corners=true;
            Ghost blinky = (Ghost)new Ghost("Blinky",game.maze,new PVector(380,136)).setModY(0); blinky.cDir.set(-1,0); blinky.nDir.set(-1,0);
            //pac.speedCheckMode = blinky.speedCheckMode = 2;
            pac.speedOverwrite = 1.25; blinky.speedOverwrite = 1.3125;
            
            Artist.animation.put(   pac,0); //TODO remove this hash element at the end of the cutscene
            Artist.animation.put(blinky,0); //TODO do the same for blinky
            
            game.mode = Mode.NORMAL;
            game.timer = -1;
          } return;
          case 5: {
            game.screen = Screen.CUTSCENE_2; //after level 5, move to cutscene 2
            game.choreoTimer=216;            //schedule for an event to happen in the cutscene in 216 frames
            
            game.tempMaze = game.maze; //store a shallow copy of the current maze
            game.maze = new Maze(-96,24,70,32,8,true);
            game.maze.game = game;
            game.maze.tunnel = new Hitbox() { public boolean hitbox(IVector v) { return false; } };
            
            Pac pac = (Pac)new Pac("Pac-Man",game.maze,new PVector(290+80,136)).setModY(0); pac.cDir.set(-1,0); pac.nDir.set(-1,0); pac.corners=true;
            Ghost blinky = (Ghost)new Ghost("Blinky",game.maze,new PVector(417+80,136)).setModY(0); blinky.cDir.set(-1,0); blinky.nDir.set(-1,0);
            //pac.speedCheckMode = blinky.speedCheckMode = 3; TODO remove all remnants of speedCheckMode
            pac.speedOverwrite = 1.1875; blinky.speedOverwrite = 1.3125;
            
            Artist.animation.put(   pac,0); //set both actors' animations
            Artist.animation.put(blinky,0); //it should be noted that these actors are removed from the hash table after we switch modes
            //TODO create a function that actually sets the principal maze of the game. In the process, it should add each actor to the animation table and remove the actors for the previous maze from said table
            
            game.mode = Mode.NORMAL;
            game.timer = -1;
          } return;
          case 9: case 13: case 17: {
            game.screen = Screen.CUTSCENE_3; //after levels 9, 13, and 17, transition to cutscene 3
            game.choreoTimer = 324;          //schedule for the cutscene to end after 550 frames
            
            game.tempMaze = game.maze; //store a shallow copy of the current maze
            game.maze = new Maze(-96,24,100,32,8,true);
            game.maze.game = game;
            game.maze.tunnel = new Hitbox() { public boolean hitbox(IVector v) { return false; } };
            
            Pac pac = (Pac)new Pac("Pac-Man",game.maze,new PVector(274+80,136)).setModY(0); pac.cDir.set(-1,0); pac.nDir.set(-1,0); pac.corners=true;
            Ghost blinky = (Ghost)new Ghost("Blinky",game.maze,new PVector(337+80,136)).setModY(0); blinky.cDir.set(-1,0); blinky.nDir.set(-1,0); blinky.setState(State.PATCHED);
            pac.speedOverwrite = 1.215; blinky.speedOverwrite = 1.3125;
            
            Artist.animation.put(pac,0);
            Artist.animation.put(blinky,0);
            
            game.mode = Mode.NORMAL;
            game.timer = -1;
          } return;
        }
        //if it was none of those levels, continue to the next level like normally
        
        UpdateManager.incrementLevel(app, game.maze); //increment the level
        
        Game.resetMaze(game.maze, false);             //reset the maze back to its default configuration (resetting items in the process)
        
        game.mode = Mode.READY; //swap back into READY mode (for beginning of level)
        game.timer = 60;        //schedule actual level start in 60 frames
      } break;
      
      case TEMP_GAME_OVER: {
        game.cycleMazes();
        game.dying=null;
        
        game.mode = Mode.READY;
        game.timer = 60;
      } break;
      
      case GAME_OVER: {
        //TODO oop this stuff so it's not just spaghetti code
        game.mazes = new CyclicArray<Maze>();
        
        game.dying = null;
        
        initStartScreen(game); //load into the start screen
        
        Artist.energizerClock = 0; //set all 3 clocks to 0
        Artist.oneUpClock = 0;
        Artist.twoUpClock = 0;
      } break;
    }
  }
  
  public static void changeScreen(Game game, PApplet app, boolean sound) { //changes game screen ASSUMING IT NEEDS TO BE CHANGED (specifically, assuming the choreo timer just became 0)
    switch(game.screen) {
      case START_SCREEN: { //start screen
        game.mode = Mode.READY;
        game.timer = 60;
        game.choreoTimer = -1;
        
        game.maze = Game.loadMaze(app).setGame(game);
        game.maze.lives    = 1; //give them exactly 1 life
        game.activePlayers = 1; //say there's exactly 1 active player
        new Brain(game.maze.get("Pac-Man"),Behavior.SCATTER); //give Pac-Man a brain
        
        game.screen = Screen.DEMO; //go to the demo screen
      } break;
      
      case CUTSCENE_1: { //first cut scene
        if(game.choreoStage==0) {
          game.choreoStage = 1;
          game.choreoTimer = 382;
          Actor actor = game.maze.get("Pac-Man"); actor.reverse=true; actor.nDir.neg(); actor.state = State.BIG; actor.setPos(-184+80,128);
          actor = game.maze.get("Blinky"); actor.reverse=true; actor.nDir.neg(); actor.state = State.VULNERABLE; actor.setPos(14+80,136); actor.speedOverwrite = 0.75;
          UpdateManager.enableFright(game.maze); game.maze.frightTimer = 1000;
        }
        else if(game.choreoStage==1) {
          game.choreoStage = 0;
          game.choreoTimer = -1;
          
          for(Actor actor : game.maze) { Artist.animation.remove(actor); } //remove all actors from the Artist's hash table
          
          game.maze = game.tempMaze; //swap back to the stored maze
          game.tempMaze = null;      //clear the temporary maze
          
          UpdateManager.incrementLevel(app, game.maze); //increment the level
          
          Game.resetMaze(game.maze, false);             //reset the maze back to its default configuration (resetting items in the process)
          
          game.screen = Screen.NORMAL;
          game.mode = Mode.READY; //swap back into READY mode (for beginning of level)
          game.timer = 60;        //schedule actual level start in 60 frames
          
          if(game.mazes.length==0) { game.screen = Screen.DEMO; } //if we were in demo mode, switch back to it (NOTE, THIS IS A HAPHAZARD WAY OF DOING IT. TODO change this)
        }
      } break;
      
      case CUTSCENE_2: { //second cut scene
        if(game.choreoStage==0) {
          game.choreoStage=1;
          game.choreoTimer=24;
          Actor blinky = game.maze.get("Blinky");
          blinky.speedOverwrite = 0.1; blinky.atom.x=135+80-0.1; blinky.caught = true;
        }
        else if(game.choreoStage==1) {
          game.choreoStage=2;
          game.choreoTimer=8;
          Actor blinky = game.maze.get("Blinky");
          blinky.speedOverwrite = 0; blinky.atom.x--;
        }
        else if(game.choreoStage==2) {
          game.choreoStage=3;
          game.choreoTimer=100;
          Actor blinky = game.maze.get("Blinky");
          blinky.speedOverwrite = 0.0001; blinky.atom.x=210.50035;
          game.mode = Mode.READY; //freeze all animations
        }
        else if(game.choreoStage==3) {
          game.choreoStage = 4;
          game.choreoTimer = 95;
          Actor blinky = game.maze.get("Blinky");
          blinky.setState(State.RIPPED);
          blinky.speedOverwrite = 0; blinky.cDir.set(1,0);
          Artist.animation.put(blinky,0);
        }
        else if(game.choreoStage==4) {
          game.choreoStage = 5;
          game.choreoTimer = 95;
          
          Actor blinky = game.maze.get("Blinky");
          Artist.animation.put(blinky,1);
        }
        else if(game.choreoStage==5) {
          game.choreoStage = 0;
          game.choreoTimer = -1;
          
          for(Actor actor : game.maze) { Artist.animation.remove(actor); } //remove all actors from the Artist's hash table
          
          game.maze = game.tempMaze; //swap back to the stored maze
          game.tempMaze = null;      //clear the temporary maze
          
          UpdateManager.incrementLevel(app, game.maze); //increment the level
          
          Game.resetMaze(game.maze, false);             //reset the maze back to its default configuration (resetting items in the process)
          
          game.screen = Screen.NORMAL;
          game.mode = Mode.READY; //swap back into READY mode (for beginning of level)
          game.timer = 60;        //schedule actual level start in 60 frames
          
          if(game.mazes.length==0) { game.screen = Screen.DEMO; } //if we were in demo mode, switch back to it (NOTE, THIS IS A HAPHAZARD WAY OF DOING IT. TODO change this)
        }
        
      } break;
      
      case CUTSCENE_3: { //third cut scene
        if(game.choreoStage==0) {
          game.choreoStage = 1;
          game.choreoTimer = 226;
          
          Actor blinky = game.maze.get("Blinky");
          blinky.setState(State.EXPOSED);
          blinky.speedOverwrite = 1.28;
          blinky.atom.x = 91; blinky.cDir.set(1,0); blinky.nDir.set(1,0);
        }
        else if(game.choreoStage==1) {
          game.choreoStage = 0;
          game.choreoTimer = -1;
          
          for(Actor actor : game.maze) { Artist.animation.remove(actor); } //remove all actors from the Artist's hash table
          
          game.maze = game.tempMaze; //swap back to the stored maze
          game.tempMaze = null;      //clear the temporary maze
          
          UpdateManager.incrementLevel(app, game.maze); //increment the level
          
          Game.resetMaze(game.maze, false);             //reset the maze back to its default configuration (resetting items in the process)
          
          game.screen = Screen.NORMAL;
          game.mode = Mode.READY; //swap back into READY mode (for beginning of level)
          game.timer = 60;        //schedule actual level start in 60 frames
          
          if(game.mazes.length==0) { game.screen = Screen.DEMO; } //if we were in demo mode, switch back to it (NOTE, THIS IS A HAPHAZARD WAY OF DOING IT. TODO change this)
        }
        
      } break;
    }
  }
  
  public static void initStartScreen(Game game) {
    Artist.animation.clear(); //remove everything from the animation hashmap
    
    game.maze = new Maze(-16,24,40,32,8,true);
    game.maze.game = game;
    game.screen = Screen.START_SCREEN;
    game.mode = Mode.READY;
    game.timer = 704;
    
    Game.loadActors(game.maze); game.maze.remove("Fruit");
    game.dying = null; //make sure to clear any currently dying actor
    
    int n=5;
    for(Actor actor : game.maze) { Artist.animation.put(actor,0); actor.cDir=new IVector(-1,0); actor.nDir=new IVector(-1,0); actor.setState(State.NORMAL); actor.speedOverwrite = 0.85*1.25; n--; }
    game.maze.get("Pac-Man").setPos(248,140); //set the positions of all actors
    game.maze.get("Blinky").setPos(264,140);
    game.maze.get("Pinky").setPos(280,140);
    game.maze.get("Inky").setPos(296,140);
    game.maze.get("Clyde").setPos(312,140);
    
    game.maze.tunnel = new Hitbox() { public boolean hitbox(IVector v) { return false; } };
  }
}
