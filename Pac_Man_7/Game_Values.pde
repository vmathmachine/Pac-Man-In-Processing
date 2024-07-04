public static class Game_Values { //a class for holding all the game values
  
  float[][] pacSpeeds;   //an array of all the pac-man speeds (depending on level & conditions)
  float[][] ghostSpeeds; //an array of all the ghost speeds (depending on level & conditions)
  
  float[][] behaviorDuration; //an array of how long each ghost behavior lasts (depending on level) (in seconds)
  
  float[] frightDuration; //the duration of fright mode (in seconds)
  
  int[] elroyDots; //how many dots should be left before Blinky switches to cruise elroy mode
  
  int[] fruitPoints; //how much each fruit is worth (divided by 10)
  
  HashMap<String,   int[]>       dotLimit = new HashMap<String,   int[]>(); //how many dots Pac-Man has to eat before each ghost can leave the ghost house
  HashMap<String, Integer> globalDotLimit = new HashMap<String, Integer>(); //how many dots have to be eaten before each ghost can leave the ghost house when using the global dot counter
  
  int[] ghostKickTime; //how long after Pac-Man stops eating dots before the ghosts start getting force kicked from the ghost house (in frames, based on level)
  
  Game_Values() { //default constructor (defaults to the values for the original 1980 game)
    
                               // normal   energizer
    pacSpeeds = new float[][] {{    0.8,      0.9 },  // level 1
                               {    0.9,      0.95},  // levels 2-4 and 21+
                               {    1  ,      1   }}; // levels 5-20
    
                                // normal   in tunnel   energizer
    ghostSpeeds = new float[][] {{  0.75,       0.4 ,      0.5 },  // level 1
                                 {  0.85,       0.45,      0.55},  // levels 2-4
                                 {  0.95,       0.5 ,      0.6 }}; // levels 5+
    
                                    // scatter   chase   scatter   chase   scatter   chase   scatter
    behaviorDuration = new float[][] {{     7,      20,        7,     20,        5,     20,    5 },  // level 1
                                      {     7,      20,        7,     20,        5,   1033, 1f/60},  // levels 2-4
                                      {     5,      20,        5,     20,        5,   1037, 1f/60}}; // levels 5+
    
                       // levels: 1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16     17 18     19+
    frightDuration = new float[] {6, 5, 4, 3, 2, 5, 2, 2, 1, 5, 2, 1, 1, 3, 1, 1, 1f/60, 1, 1f/60};
    
                 // levels: 1   2  3-5  6-8  9-11  12-14  15-18  19+
    elroyDots = new int[] {20, 30, 40,  50,   60,   80,   100, 120};
    
    fruitPoints = new int[] {10, 30, 50, 70, 100, 200, 300, 500};
    
                           //levels:  1    2  3+
    dotLimit.put("Blinky", new int[] {0,   0, 0});
    dotLimit.put( "Pinky", new int[] {0,   0, 0});
    dotLimit.put(  "Inky", new int[] {30,  0, 0});
    dotLimit.put( "Clyde", new int[] {60, 50, 0});
    
    globalDotLimit.put("Pinky",7); globalDotLimit.put("Inky",17); //Pinky leaves when 7 dots are eaten, Inky leaves when 17 dots are eaten.
    //Blinky never stays in the house, Clyde only leaves using personal dot counters or the timer
                     
                     //levels: 1-4    5+
    ghostKickTime = new int[] {4*60, 3*60}; //first 4 seconds, then 3 seconds
  }
  
  
  public static int levelMapping(int level, boolean hard) { //given the true level, and the difficulty, returns what the "effective" level is
    if(!hard) { return level; } //if not on hard mode, the effective level is the true level
    
    //in hard mode, earlier levels act like later levels, identical in every way except which fruit you get
    switch(level) { //switch the true level
      case 1: return 2; //level 1 acts like level 2
      case 2: return 4; //level 2 acts like level 4
      case 3: return 5; //level 3 acts like level 5
      default:          //other levels:
        if(level<=15) { return level+3; } //levels 4-15 act like levels 7-18
        return level+5;                   //levels 16+ act like levels 21+
    }
  }
  
  public int elroyDots1(final int level) { //the number of dots before blinky can go into cruise elroy mode
    int index;
    if     (level== 1) { index=0; }
    else if(level== 2) { index=1; }
    else if(level<= 5) { index=2; }
    else if(level<= 8) { index=3; }
    else if(level<=11) { index=4; }
    else if(level<=14) { index=5; }
    else if(level<=18) { index=6; }
    else               { index=7; }
    return elroyDots[index];
  }
  
  public int elroyDots2(final int level) { return elroyDots1(level) >> 1; } //return the number of dots to get to the first stage, divided by 2
  
  public int fruitIndex(final int level) { //computes the index of the fruit corresponding to each level
    if(level==1)  { return 0; } //1: cherry
    if(level==2)  { return 1; } //2: strawberry
    if(level<=4)  { return 2; } //3-4: orange
    if(level<=6)  { return 3; } //5-6: apple
    if(level<=8)  { return 4; } //7-8: melon
    if(level<=10) { return 5; } //9-10: flagship
    if(level<=12) { return 6; } //11-12: bell
    return 7;                   //13+: key
  }
  
  public float elroySpeed1(int level) { //TODO what is this even for, again?
    if(level<21) { return 0; }
    return 0;
  }
  
  public Behavior getBehavior(int level, int time) { //given the level & the time, find what behavior the ghosts are supposed to be operating under
    int index1 = level==1 ? 0 : (level<=4 ? 1 : 2); //the level index to search through
    int index2 = 0;                                 //the time index to search
    for(index2=0; index2<7 && time>=0; ++index2) {  //loop through the second index until we run out of indices or we run out of time
      time -= round(60*behaviorDuration[index1][index2]);  //each iteration, subtract from the time the duration of each phase
    }
    return ((index2&1)==0 ^ time>=0) ? Behavior.CHASE : Behavior.SCATTER; //return chase if index is even, scatter if it's odd (increment index if it's still positive)
  }
  
  
  
  public static boolean shouldLeave(Ghost ghost) { //returns whether or not a ghost should leave the ghost house (assumuing they're patrolling, ignoring the timeSinceLastDot
    if(ghost.maze.doGlobalDotCounter) { //global dot counter:
      Integer timer = ghost.game.values.globalDotLimit.get(ghost.name); //find how many dots it takes for them to leave
      if(timer!=null) { return ghost.maze.globalDotCounter == timer; }  //if not null, return whether the global dot counter equals this
      return ghost.name.equals("Blinky");                               //otherwise, return true if Blinky, false if Clyde
    }
    else { //individual dot counters:
      //int lev = ghost.maze.levelMap; //find the effective level
      int lev = ghost.maze.level; //find the maze level (I don't think level mapping applies here)
      if(lev>3) { lev=3; } //max it out at 3
      
      return (ghost.dotCounter >= ghost.game.values.dotLimit.get(ghost.name)[lev-1]); //return true iff the dot counter is at least as much as the dot limit
    }
  }
}
