/*
Cyclic Array class
enums
interfaces
misc methods


*/



public static class CyclicArray<Type> implements Iterable<Type> {
  final int length; //# of elements
  Type[] array;     //array of the elements
  
  public CyclicArray(Type... arr) { //initializes cyclic array
    length = arr.length;
    array = arr;
  }
  
  Type get(int i) { return array[Math.floorMod(i,length)]; } //gets the i-th element
  void set(int i, Type t) { array[Math.floorMod(i,length)]=t; } //sets the i-th element
  
  @Override
  public Iterator<Type> iterator() { //iterates through the list
    return new Iterator<Type>() { //declare a new type of iterator
      private int index = -1;
      
      @Override
      public boolean hasNext() { return index<length-1; }
      
      @Override
      public Type next() {
        index = (index+1)%length; //add 1 and modulo by size
        return array[index];      //return the array at that position
      }
    };
  }
}


public static enum Screen {
  //screens
  START_SCREEN, CREDIT_SCREEN, DEMO,  //start of game
  NORMAL,                             //during game
  CUTSCENE_1, CUTSCENE_2, CUTSCENE_3; //cutscenes
  
  public boolean isCutscene() { return this==CUTSCENE_1 || this==CUTSCENE_2 || this==CUTSCENE_3; }
}

public static enum Mode {
  //modes
  INTRO, READY, NORMAL, EAT_GHOST, MAZE_FINISHED_1, MAZE_FINISHED_2, PAC_DEATH_1, PAC_DEATH_2, PAC_DEATH_3, GAME_OVER, TEMP_GAME_OVER;
  
  public boolean isPlaying() { return this==NORMAL; }
  public boolean pacIsDying() { return this==PAC_DEATH_1 || this==PAC_DEATH_2 || this==PAC_DEATH_3; }
  public boolean canUpdate() { return this==NORMAL /*|| this==PAC_DEATH_1*/ || this==EAT_GHOST; }
  
  public Mode increment() { switch(this) { //given this mode, increment to the next one
    case INTRO: return READY;
    case MAZE_FINISHED_1: return MAZE_FINISHED_2;
    case PAC_DEATH_1: return PAC_DEATH_2; case PAC_DEATH_2: return PAC_DEATH_3;
    case MAZE_FINISHED_2: case PAC_DEATH_3: case GAME_OVER: case TEMP_GAME_OVER: return READY;
    case READY: case EAT_GHOST: case NORMAL: return NORMAL;
    
    default: return null;
  } }
  
  public int nextTimer() { switch(this) {
    case INTRO: return 128;
    case READY: return -1;
    case PAC_DEATH_1: return 88;
    case PAC_DEATH_2: return 16;
    case PAC_DEATH_3: return 60;
    case EAT_GHOST: return -1;
    case MAZE_FINISHED_1: return 128;
    case MAZE_FINISHED_2: return 60;
    case GAME_OVER: return 704;
    case TEMP_GAME_OVER: return 60;
    default: println("AAAAAAAAAAH! timer was 0 in "+this); return -1;
  } }
};

enum Item { NONE, PAC_DOT, ENERGIZER }; //things that can be inside a square
enum Barrier { WALL, GATE, PASSAGEWAY};

public enum PathFinding { TOWARD, AWAY, RANDOM, PATROL } //the 4 pathfinding modes: move toward, move away, pick a random direction, or patrol the base

public enum Behavior {
  SCATTER, CHASE, FRIGHTENED, EATEN, BASE_PATROL, BASE_ENTER, BASE_EXIT_1, BASE_EXIT_2; //the 8 behaviors: scatter, chase, frightened, eaten, as well as 4 base-based behaviors
  
  boolean isBase() { return this==BASE_PATROL || this==BASE_ENTER || this==BASE_EXIT_1 || this==BASE_EXIT_2; } //whether it's chilling in the base
  boolean canChange() { return !isBase() && this!=EATEN; } //true means it can change during game events, false means it can only change when scheduled to
  boolean isNormal() { return this==SCATTER || this==CHASE; } //whether it's one of the 2 normal behaviors
}

public static enum State { NORMAL, VULNERABLE, EATEN, BIG, DYING, INVISIBLE, RIPPED, PATCHED, EXPOSED }

public static enum CreditRate { HALF, ONE, TWO, FREE }

//SCATTER, CHASE, FRIGHTENED, EATEN, BASE_PATROL, BASE_ENTER, BASE_EXIT_1, BASE_EXIT_2
//BASE: patrol, exit 1, exit 2, enter, 




public static interface Hitbox { public boolean hitbox(IVector v); } //a makeshift lambda function used for detecting hitboxes of certain areas of the maze

public interface TargetFinder { //used to find the target tile
  public Object[] findTarget(Actor body, Actor... vars);  //finds the target tile AND the pathfinding mode
}





public static float nudge(float start, float dest, float amt) {  //nudges it towards a point (dest) by a certain amount (amt)
  if(abs(start-dest) <= amt) { return dest;      } //if the distance is smaller than the increment amount, just move to the destination
  if(start > dest)           { return start-amt; } //otherwise, if the start is after the destination, move backwards
  else                       { return start+amt; } //but if the start is before the destination, move forward
}

public static float nudge(PVector init, PVector targ, float speed) { //nudges init towards targ by the amount speed
  float initX = init.x, initY = init.y;
  init.x = nudge(init.x,targ.x,speed);
  init.y = nudge(init.y,targ.y,speed);
  return max(abs(initX-init.x),abs(initY-init.y));
  //return init;
}

public static char directoryCharacter() {
  return System.getProperty("os.name").contains("Windows") ? '\\' : '/';
}
