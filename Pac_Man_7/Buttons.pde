public static class Button {
  float x, y; //x & y of top left
  float w, h; //width & height
  
  String text; //text
  
  color back=#000080, fore=#FFFFFF, stroke=#000000; //background, foreground, and stroke color
  
  Activator func; //what happens when you press it
  
  boolean enabled=true; //whether it's active or greyed out
  
  Button(float x2, float y2, float w2, float h2, String txt, color b, color f, color s, Activator f2) { //normal constructor
    x=x2; y=y2; w=w2; h=h2; text=txt; back=b; fore=f; stroke = s;
    func = f2;
  }
  
  Button(float x2, float y2, float w2, float h2, String txt, Activator f2) { //constructor with default colors
    x=x2; y=y2; w=w2; h=h2; text=txt;
    func = f2;
  }
  
  void display(PApplet app) {
    app.stroke(stroke);
    if(!enabled) {
      app.fill(#808080);
    }
    else if(hitbox(app.mouseX/scale,app.mouseY/scale)) {
      app.fill(lerpColor(back,#FFFFFF,app.mousePressed ? 0.75 : 0.5,RGB));
    }
    else { app.fill(back); }
    
    app.rect(x,y,w,h);
    app.fill(fore); app.textAlign(CENTER,CENTER); app.text(text,x+0.5*w,y+0.5*h);
  }
  
  boolean hitbox(int mouseX, int mouseY) {
    return enabled && mouseX>x && mouseX<x+w && mouseY>y && mouseY<y+h;
  }
}

void loadButtons(final Game game, final ArrayList<Button> buttons) {
  float y = 200;
  buttons.add(new Button(15,y,60,20,"Restart",new Activator() { public void activate() {
    game.restartGame();
  } }));
  
  final int rackInd = buttons.size();
  y=200;
  buttons.add(new Button(145,y,65,20,"Disabled",new Activator() { public void activate() {
    game.rackTest ^= true;
    buttons.get(rackInd).text = game.rackTest ? "Enabled" : "Disabled";
  } }));
  
  y=240;
  buttons.add(new Button(15,y,60,20,"Lives++",new Activator() { public void activate() {
    game.maze.incrementLives();
  } }));
  buttons.add(new Button(75,y,60,20,"Lives--",new Activator() { public void activate() {
    game.maze.decrementLives();
  } }));
  
  final int invincibleInd = buttons.size();
  y=240;
  buttons.add(new Button(145,y,65,20,"Disabled",new Activator() { public void activate() {
    game.maze.invincible ^= true;
    buttons.get(invincibleInd).text = game.maze.invincible ? "Enabled" : "Disabled";
  } }));
  
  
  final int lifeInd = buttons.size()-1;
  y=290;
  for(int n=1;n<=5;n++) {
    final int n2 = n;
    buttons.add(new Button(20*n+32,y,20,20,n+"",new Activator() { public void activate() {
      game.livesInitial = n2;
      for(int n3=lifeInd+1;n3<=lifeInd+6;n3++) { buttons.get(n3).enabled = (n2+lifeInd != n3); }
      game.restartGame();
    } }));
  }
  buttons.add(new Button(152,y,20,20,"∞",new Activator() { public void activate() {
    game.livesInitial = Integer.MIN_VALUE;
    for(int n3=lifeInd+1;n3<=lifeInd+6;n3++) { buttons.get(n3).enabled = n3!=lifeInd+6; }
    game.restartGame();
  } }));
  
  
  final int scoreInd = buttons.size();
  y=330;
  for(int n=scoreInd;n<=scoreInd+2;n++) {
    final int n2 = n;
    buttons.add(new Button(22+45*(n2-scoreInd),y,45,20,5*(n2-scoreInd)+10+"000",new Activator() { public void activate() {
      game.scoreForOneUp = 500*(n2-scoreInd)+1000;
      for(int n3=scoreInd;n3<=scoreInd+3;n3++) { buttons.get(n3).enabled = n3!=n2; }
      game.restartGame();
    } }));
  }
  buttons.add(new Button(22+45*3,y,45,20,"No",new Activator() { public void activate() {
    game.scoreForOneUp = 0;
    for(int n=scoreInd;n<=scoreInd+3;n++) { buttons.get(n).enabled = n!=scoreInd+3; }
    game.restartGame();
  } }));
  
  final int creditInd = buttons.size();
  final String[] texts = {"2C1C","1C1C","1C2C","Free"};
  y=370;
  final CreditRate[] rates = {CreditRate.HALF, CreditRate.ONE, CreditRate.TWO, CreditRate.FREE};
  for(int n=creditInd;n<=creditInd+3;n++) {
    final int n2 = n;
    buttons.add(new Button(42+35*(n-creditInd),y,35,20,texts[n-creditInd],new Activator() { public void activate() {
      game.creditRate = rates[n2-creditInd]; //set the credit rate
      
      for(int n3=creditInd;n3<=creditInd+3;n3++) { buttons.get(n3).enabled = (n2!=n3); } //deactivate this button, reactivate the others
    } }));
  }
  
  final int diffInd = buttons.size();
  y=410;
  buttons.add(new Button(15,y,50,20,"Normal",new Activator() { public void activate() {
    game.hard = false;  //switch to normal mode
    game.restartGame(); //restart game
    buttons.get(diffInd).enabled = false; buttons.get(diffInd+1).enabled = true; //enable hard button, disable normal button
  } }));
  buttons.add(new Button(65,y,50,20,"Hard",new Activator() { public void activate() {
    game.hard = true;   //switch to hard mode
    game.restartGame(); //restart game
    buttons.get(diffInd).enabled = true; buttons.get(diffInd+1).enabled = false; //disable hard button, enable normal button
  } }));
  
  
  final int altInd = buttons.size();
  y=410;
  buttons.add(new Button(145,y,65,20,"Disabled",new Activator() { public void activate() {
    game.altGhostNames ^= true;
    buttons.get(altInd).text = game.altGhostNames ? "Enabled" : "Disabled";
  } }));
  
  
  final int charIndex = buttons.size();
  y = 460;
  buttons.add(new Button(32,y,60,20,"Pac-Man",switchPlayerTo("Pac-Man")));
  buttons.add(new Button(92,y,50,20,"Blinky",switchPlayerTo("Blinky")));
  buttons.add(new Button(142,y,50,20,"Pinky",switchPlayerTo("Pinky")));
  buttons.add(new Button(92,y+20,50,20,"Inky",switchPlayerTo("Inky")));
  buttons.add(new Button(142,y+20,50,20,"Clyde",switchPlayerTo("Clyde")));
  
  buttons.get(charIndex).back = #FFFF00; buttons.get(charIndex+1).back = #FF0000; buttons.get(charIndex+2).back = #FFAAFF;
  buttons.get(charIndex).fore = #000000; buttons.get(charIndex+3).back = #00FFFF; buttons.get(charIndex+4).back = #FFAA55;
  buttons.get(charIndex+3).fore = #000000;
  
  
  buttons.get(game.hard ? diffInd+1 : diffInd).enabled = false;
  if(game.livesInitial==Integer.MIN_VALUE) { buttons.get(6+lifeInd).enabled = false; }
  else { buttons.get(game.livesInitial+lifeInd).enabled = false; }
  switch(game.scoreForOneUp) { case 1000: buttons.get(scoreInd).enabled=false; break;
                               case 1500: buttons.get(scoreInd+1).enabled=false; break;
                               case 2000: buttons.get(scoreInd+2).enabled=false; break;
                               case 0: buttons.get(scoreInd+3).enabled=false; }
  switch(game.creditRate) { case HALF: buttons.get(creditInd).enabled=false; break;
                            case  ONE: buttons.get(creditInd+1).enabled=false; break;
                            case  TWO: buttons.get(creditInd+2).enabled=false; break;
                            case FREE: buttons.get(creditInd+3).enabled=false; }
  
}

interface Activator { //interface for button functionality
  void activate();    //method to be called upon activation
}

Activator switchPlayerTo(final String name) { return new Activator() { public void activate() {
  Actor newPlayer = game.maze.get(name);
  if(game.player1==null || game.player1==newPlayer) { return; }
  
  giveBrain(game.player1);
  /*if(game.player1.didCenter) {
    game.player1.brain.setNextDirection(game.player1.tile);
    
    game.player1.cDir = game.player1.nDir;
  }
  else { game.player1.setNextDirection(); }*/
  //println(game.player1.nDir, game.player1.cDir);
  //if(game.player1.didCenter) { game.player1.cDir =  }
  
  game.player1 = game.player2 = newPlayer;
  game.player1.brain = null;
  game.maze.player1 = game.maze.player2 = name;
} }; }
