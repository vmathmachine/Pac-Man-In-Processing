public static class IVector { //a vector of, get this, integers. Yes, because that's actually essential in storing pixel positions
  ////////////////////// ATTRIBUTES //////////////////////

  public int x=0, y=0; //x & y positions
  
  ///////////////////// CONSTRUCTORS /////////////////////
  
  public IVector()                           {             } //init to 0,0
  public IVector(final int x_, final int y_) { x=x_; y=y_; } //set position
  public IVector(PVector v)  { x=round(v.x); y=round(v.y); } //round the floating point position
  
  ///////////////////// BASIC OBJECT FUNCTIONS //////////////////////
  
  public IVector set(final int x2, final int y2) { x= x2; y= y2; return this; } //set position
  public IVector set(IVector v)                  { x=v.x; y=v.y; return this; } //copy from vector
  public IVector set(PVector v)                  { x=round(v.x); y=round(v.y); return this; } //round the floating point position
  
  @Override
  public IVector clone() { return new IVector(x,y); } //clone
  public IVector copy () { return clone();          } //copy
  
  public PVector toPVector() { return new PVector(x,y); } //cast to a PVector
  
  public int magSq() { return x*x+y*y; } //magnitude squared
  //public float mag() { return sqrt(magSq()); } //magnitude (shouldn't have to be used!)
  
  ////////////////////////// ARITHMETIC ////////////////////////////////
  
  public IVector add(IVector v)      { x+=v.x; y+=v.y; return this; }
  public IVector add(int x2, int y2) { x+= x2; y+= y2; return this; }
  public static IVector add(IVector v1, IVector v2)                 { return new IVector(v1.x+v2.x, v1.y+v2.y); }
  public static IVector add(IVector v1, IVector v2, IVector target) { return target.set (v1.x+v2.x, v1.y+v2.y); }
  
  public IVector sub(IVector v)      { x-=v.x; y-=v.y; return this; }
  public IVector sub(int x2, int y2) { x-=x2;  y-=y2;  return this; }
  public static IVector sub(IVector v1, IVector v2)                 { return new IVector(v1.x-v2.x, v1.y-v2.y); }
  public static IVector sub(IVector v1, IVector v2, IVector target) { return target.set (v1.x-v2.x, v1.y-v2.y); }
  
  public IVector mult(int n)         { x*=n; y*=n; return this; }
  public static IVector mult(IVector v, int n)                 { return new IVector(v.x*n, v.y*n); }
  public static IVector mult(IVector v, int n, IVector target) { return target.set (v.x*n, v.y*n); }
  
  public PVector mult(float n)       { return new PVector(x*n,y*n); }
  public static PVector mult(IVector v, float n)                 { return new PVector(v.x*n, v.y*n); }
  public static PVector mult(IVector v, float n, PVector target) { return target.set (v.x*n, v.y*n); }
  
  ////////////////// MORE ABSTRACT ARITHMETIC (i.e. bitwise operations) /////////////////////////////////
  
  public IVector div(int n)          { x/=n; y/=n; return this; } //is basically useless unless it's an exact multiple of n in both directions
  public static IVector div(IVector v, int n)                 { return new IVector(v.x/n, v.y/n); }
  public static IVector div(IVector v, int n, IVector target) { return target.set (v.x/n, v.y/n); }
  
  public IVector mod(int w, int h) { x=modPos(x, w); y=modPos(y, h); return this; } //used primarily for the fact that the pacman maze is homeomorphic to a torus, thus the position gets modded by the mazes dimensions
  public static IVector mod(IVector v, int w, int h)                 { return      v.set(modPos(v.x, w), modPos(v.y, h)); }
  public static IVector mod(IVector v, int w, int h, IVector target) { return target.set(modPos(v.x, w), modPos(v.y, h)); }
  
  public IVector modIEEE(int w, int h)                                   { x=IEEEremainder(x, w); y=IEEEremainder(y, h); return this; } //used for difference vectors, so they wrap around AND point in multiple directions
  public static IVector modIEEE(IVector v, int w, int h)                 { return      v.set(IEEEremainder(v.x, w), IEEEremainder(v.y, h)); }
  public static IVector modIEEE(IVector v, int w, int h, IVector target) { return target.set(IEEEremainder(v.x, w), IEEEremainder(v.y, h)); }
  
  public IVector and(int x2, int y2)                                   { x&=x2; y&=y2; return this;          } //bitwise AND
  public static IVector and(IVector v, int x2, int y2)                 { return new IVector(v.x&x2, v.y&y2); }
  public static IVector and(IVector v, int x2, int y2, IVector target) { return target.set (v.x&x2, v.y&y2); }
  
  public IVector or(int x2, int y2)                                   { x|=x2; y|=y2; return this;          } //bitwise OR
  public static IVector or(IVector v, int x2, int y2)                 { return new IVector(v.x|x2, v.y|y2); }
  public static IVector or(IVector v, int x2, int y2, IVector target) { return target.set (v.x|x2, v.y|y2); }
  
  public IVector xor(int x2, int y2)                                   { x^=x2; y^=y2; return this;          } //bitwise XOR
  public static IVector xor(IVector v, int x2, int y2)                 { return new IVector(v.x^x2, v.y^y2); }
  public static IVector xor(IVector v, int x2, int y2, IVector target) { return target.set (v.x^x2, v.y^y2); }
  
  public IVector not()                                 { x=~x; y=~y; return this;        } //bitwise NOT
  public static IVector not(IVector v)                 { return new IVector(~v.x, ~v.y); }
  public static IVector not(IVector v, IVector target) { return target.set(~v.x, ~v.y); }
  
  public IVector shiftLeft(int n)                                   { x<<=n; y<<=n; return this;          }
  public static IVector shiftLeft(IVector v, int n)                 { return new IVector(v.x<<n, v.y<<n); }
  public static IVector shiftLeft(IVector v, int n, IVector target) { return target.set (v.x<<n, v.y<<n); }
  
  public IVector shiftRight(int n)                                   { x>>=n; y>>=n; return this;          }
  public static IVector shiftRight(IVector v, int n)                 { return new IVector(v.x>>n, v.y>>n); }
  public static IVector shiftRight(IVector v, int n, IVector target) { return target.set (v.x>>n, v.y>>n); }
  
  public IVector glitchedAdd(IVector v)      { x+=v.x; y+=v.y; if(v.y<0) { x+=v.y; } return this; }
  public IVector glitchedAdd(int x2, int y2) { x+=x2;  y+=y2;  if( y2<0) { x+= y2; } return this; }
  public static IVector glitchedAdd(IVector v1, IVector v2)                 { int x=v1.x+v2.x, y=v1.y+v2.y;           if(v2.y<0) { x+=v2.y;        } return new IVector(x,y); }
  public static IVector glitchedAdd(IVector v1, IVector v2, IVector target) { target.x=v1.x+v2.x; target.y=v1.y+v2.y; if(v2.y<0) { target.x+=v2.y; } return target;           }
  
  /////////////////////////// VECTOR FUNCTIONS ////////////////////////////
  
  public int distSq(IVector v)                     { return (x-v.x)*(x-v.x)+(y-v.y)*(y-v.y);                 } //return distance squared
  public static int distSq(IVector v1, IVector v2) { return (v1.x-v2.x)*(v1.x-v2.x)+(v1.y-v2.y)*(v1.y-v2.y); } //return distance squared
  //public float dist(IVector v) { return sqrt(distSq(v)); }
  
  public int dot(IVector v)      { return x*v.x+y*v.y; } //return dot product
  public int dot(int x2, int y2) { return x* x2+y* y2; } //return dot product
  public static int dot(IVector v1, IVector v2) { return v1.x*v2.x+v1.y*v2.y; }
  
  public float dot(PVector v)          { return x*v.x+y*v.y; } //return dot product
  public float dot(float x2, float y2) { return x* x2+y* y2; } //return dot product
  public static float dot(IVector v1, PVector v2) { return v1.x*v2.x+v1.y*v2.y; }
  
  public int cross(IVector v)      { return x*v.y-y*v.x; } //return cross product (technically, this is actually the "perpendicular dot product")
  public int cross(int x2, int y2) { return x* y2-y* x2; }
  public static int cross(IVector v1, IVector v2) { return v1.x*v2.y-v1.y*v2.x; }
  
  public float cross(PVector v)          { return x*v.y-y*v.x; } //return cross product
  public float cross(float x2, float y2) { return x* y2-y* x2; }
  public static float cross(IVector v1, PVector v2) { return v1.x*v2.y-v1.y*v2.x; }
  
  ////////////////////////// VECTOR TRANSFORMATIONS /////////////////////////////
  
  public        IVector neg()          { x=-x; y=-y; return this;        } //negates & returns
  public static IVector neg(IVector v) { return new IVector(-v.x, -v.y); } //returns negated copy
  
  public IVector rot90CCW() { final int z=x; x=-y; y=z; return this; } //rotates 90 counterclockwise
  public IVector rot90CW () { final int z=x; x=y; y=-z; return this; } //rotates 90 clockwise
  public static IVector rot90CCW(IVector v) { return new IVector(-v.y, v.x); }
  public static IVector rot90CW (IVector v) { return new IVector(v.y, -v.x); }
  
  ///////////////////////// INHERITED METHODS ////////////////////////////////////
  
  @Override
  public String toString() { return "[ "+x+", "+y+" ]"; } //cast to string
  public int[] array() { return new int[] {x,y}; } //return as array
  
  @Override
  public boolean equals(final Object obj) {
    if(obj instanceof IVector) { final IVector v = (IVector)obj; return v.x==x && v.y==y; } //return true if it's an IVector and the components equal
    return false;  //return false if not an IVector
  }
  
  public boolean equals(int x2, int y2) { return x==x2 && y==y2; }
  
  @Override
  public int hashCode() { return 961+31*x+y; } //a decent copy of what goes on with the PVector hashcode
}



public static int sgn(float inp) { return inp>0 ? 1 : inp==0 ? 0 : -1; }

public static int modPos(int a, int b) { a%=b; if(a<0) { a+=b; } return a; } //performs a modulo that's never negative

public static int IEEEremainder(int a, int b) { a%=b; if(a>(b<<1)) { a-=b; } if(a<=-(b<<1)) { a+=b; } return a; } //performs the modulo that's closest to 0

public static float modPos(float a, float b) { a%=b; if(a<0) { a+=b; } return a; }

public static float closestMIM(float a, float b, float mod) { //returns the closest mod-integer multiple (MIM) of b to a (meaning an integer-plus-a-modulus multiple)
  return (round(a/b-mod)+mod)*b;
}

public static PVector closestMIM(PVector v, float cell, float modx, float mody) {
  return new PVector(closestMIM(v.x,cell,modx),closestMIM(v.y,cell,mody)); //returns the position in the middle (or wherever) of a tile that's closest to the vector v
}
