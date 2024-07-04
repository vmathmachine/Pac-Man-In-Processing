public static class DeeJay { //responsible for loading and managing the audio
  
  public static SoundFile intro, intermission, deathSound, eatFruit, eatGhost, oneUp, credit, waka1, waka2, blueGhosts, fleeingGhosts;
  public static SoundFile ghostMove[];
  
  public static SoundFile ambience;
  
  public static void loadSounds(final PApplet app) { //loads and initializes all sounds
    String dir = "assets"+dirChar+"Sounds"+dirChar;
    intro        =new SoundFile(app,dir+"pacman_beginning.wav"     ); //load all the miscellaneous sound files
    intermission =new SoundFile(app,dir+"pacman_intermission.wav"  );
    deathSound   =new SoundFile(app,dir+"pacman_death.wav"         );
    eatFruit     =new SoundFile(app,dir+"pacman_eatfruit.wav"      );
    eatGhost     =new SoundFile(app,dir+"pacman_eatghost.wav"      );
    oneUp        =new SoundFile(app,dir+"pacman_extrapac.wav"      );
    credit       =new SoundFile(app,dir+"pacman credit sound 1.wav");
    waka1        =new SoundFile(app,dir+"Waka P1.wav"              );
    waka2        =new SoundFile(app,dir+"Waka P2.wav"              );
    blueGhosts   =new SoundFile(app,dir+"Blue Ghosts.wav"          );
    fleeingGhosts=new SoundFile(app,dir+"Fleeing Ghosts.wav"       );
    ghostMove=new SoundFile[] {new SoundFile(app,dir+"Ghost Movement - 1.wav"),new SoundFile(app,dir+"Ghost Movement - 2.wav"),new SoundFile(app,dir+"Ghost Movement - 3.wav"),
                               new SoundFile(app,dir+"Ghost Movement - 4.wav"),new SoundFile(app,dir+"Ghost Movement - 5.wav")};
  }
  
  public static SoundFile ambientTrack(final Game game) {
    Maze maze = game.maze; //load the maze
    
    if(game.screen == Screen.CUTSCENE_1 || game.screen == Screen.CUTSCENE_2 || game.screen == Screen.CUTSCENE_3) {
      return intermission;
    }
    
    if(game.isPausedCompletely || game.mode == Mode.PAC_DEATH_1 || game.mode == Mode.PAC_DEATH_2 || game.mode == Mode.PAC_DEATH_3 || game.mode == Mode.READY ||
       game.mode == Mode.INTRO || game.mode == Mode.MAZE_FINISHED_1 || game.mode == Mode.MAZE_FINISHED_2 || game.screen == Screen.START_SCREEN ||
       game.screen == Screen.CREDIT_SCREEN || game.screen == Screen.DEMO || game.mode == Mode.GAME_OVER || game.mode == Mode.TEMP_GAME_OVER) { return null; }
    
    for(Actor ghost : maze) { if(ghost instanceof Ghost && ghost.state==State.EATEN) { return fleeingGhosts; } } //if any ghosts are fleeing, return that as the ambient track
    
    if(maze.frightTimer!=0) { return blueGhosts; } //otherwise, if in fright mode, return the corresponding track
    
    if(maze.dotsLeft>=128) { return ghostMove[0]; } //128 or more dots left: initial ambient track
    if(maze.dotsLeft>= 64) { return ghostMove[1]; } //64-127 dots left: second ambient track
    if(maze.dotsLeft>= 32) { return ghostMove[2]; } //32-63 dots left: third ambient track
    if(maze.dotsLeft>= 16) { return ghostMove[3]; } //16-31 dots left: fourth ambient track
    return ghostMove[4];                            //15 or fewer dots left: fifth ambient track
  }
  
  public static void manageAmbience(final Game game) {
    SoundFile ambience = DeeJay.ambientTrack(game); //find the correct ambient track
    if(ambience!=DeeJay.ambience) { //if that track isn't currently playing
      if(DeeJay.ambience != null) { DeeJay.ambience.stop(); } //if not null, silence the previous ambient track
      if(       ambience != null) {        ambience.loop(); } //if not null, play the new ambient track on repeat
      DeeJay.ambience = ambience;                             //set the new ambient track
    }
  }
}
