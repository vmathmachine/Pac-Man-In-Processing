public static class Grid { //one grid in a maze
  private byte collision=0; //4 bits to decide if the grid square is solid on the right, bottom, left, and top, respectively (1=solid, 0=intangible, the first 4 bits are unused)
  
  private Item item = Item.NONE; //the item inside (default to none)
  private Barrier barrier = Barrier.WALL; //what type of barrier it is
  
  Grid() { } //default constructor (empty)
  
  Grid(String def) { //construct with description
    switch(def.toLowerCase()) { //not case sensitive
      case "empty":                                            break; //empty: already set by default
      case "wall": collision=15;                               break; //wall: all sides are solid
      case "gate": collision=5; barrier=Barrier.GATE;          break; //gate: top and bottom are solid, but only for certain actors
      case "passage": collision=4; barrier=Barrier.PASSAGEWAY; break; //passage: bottom is solid, but only for certain actors
      
      case "pac-dot"  : item=Item.PAC_DOT;   break; //pac dot
      case "energizer": item=Item.ENERGIZER; break; //energizer
      
      //here, you can define anything else you want
      
      default: throw new RuntimeException("Cannot define a grid square through the phrase \""+def+"\""); //tell us in case we spelled something wrong
    }
  }
  
  Grid(char def) { //constructor specified by a character (somehow, this has more outcomes)
                   //this exists so you can create your own custom maze through a configuration file
    switch(def) { //each grid square depends on the character
      case ' ':                                    break; //empty grid
      case '*': collision=15;                      break; //wall
      case 'g': collision=5; barrier=Barrier.GATE; break; //gate
      case '.': item = Item.PAC_DOT;               break; //pac dot
      case 'o': item = Item.ENERGIZER;             break; //energizer
      
      case 'd': setSolid(1,0,0,0); break; //right wall
      case '_': setSolid(0,1,0,0); break; //bottom wall
      case 'b': setSolid(0,0,1,0); break; //left wall
      case '-': setSolid(0,0,0,1); break; //top wall
      
      case 'L': setSolid(0,1,1,0); break; //bottom left
      case 'F': setSolid(0,0,1,1); break; //top left
      case 'J': setSolid(1,1,0,0); break; //bottom right
      case 'T': setSolid(1,0,0,1); break; //top right
      case '=': setSolid(0,1,0,1); break; //horizontal
      case '|': setSolid(1,0,1,0); break; //vertical
      
      case 'C': setSolid(0,1,1,1); break; //all but right
      case 'D': setSolid(1,1,0,1); break; //all but left
      case 'U': setSolid(1,1,1,0); break; //all but top
      case 'n': setSolid(1,0,1,1); break; //all but bottom
      
      case 'P': item = Item.PAC_DOT;                              //blocked passageway with a Pac-Dot
      case 'p': collision=4; barrier = Barrier.PASSAGEWAY; break; //blocked passageway in general
    }
    
     //feel free to add as many extra cases as you'd like, so you may customize to your heart's content :)
  }
  
  Item getItem() { return item; }                                                          //getter for item
  Barrier getBarrier() { return barrier; }                                                 //getter for barrier
  boolean up  () { return (collision&1)==1; } boolean down () { return (collision&4)==4; }
  boolean left() { return (collision&2)==2; } boolean right() { return (collision&8)==8; } //getters for the solidness of each side
  
  
  Grid setItem(Item i) { if(i!=null) { item=i; } return this; } //sets item
  Grid setBarrier(Barrier b) { if(b!=null) { barrier=b; } return this; } //sets barrier
  Grid setSolid(int r, int d, int l, int u) { collision=(byte)((r<<3)|(d<<2)|(l<<1)|u); return this; }    //sets the solidity of each side with integers (ONLY works if ALL integers are 0 or 1)
  Grid setSolid(boolean r, boolean d, boolean l, boolean u) { return setSolid(r?1:0,d?1:0,l?1:0,u?1:0); } //sets the solidity of each side with booleans
  
  String specifier() { //parses the type of grid into a string
    switch(item) { case PAC_DOT: return "pac-dot"; case ENERGIZER: return "energizer"; } //if it contains something, return that something (as a string)
    if(collision== 0) { return "empty"; }
    if(collision==15) { return "wall";  }
    return "complex wall";
  }
  
  @Override
  Grid clone() {
    Grid clone = new Grid(); clone.item=item; clone.barrier=barrier; clone.collision=collision;
    return clone;
  }
}
