
package randomtopology;
import java.lang.*;
import static java.lang.Math.abs;
import static java.lang.Math.sqrt;
public class Topology {

private double axisx = 0;
private double axisy = 0;
private int number = 0;  
    
    public Topology(){
        axisx = 0;
        axisy =0;
        number =0;
    }
public void Setaxisx (double axisx){
    this.axisx = axisx;
}
public void Setaxisy (double axisy){
    this.axisy = axisy;
}
public void Setnumber (int number){
    this.number = number;
}
public double Getaxisx(){
    return axisx;
}
public double Getasisy(){
    return axisy;
}
public double Getnumber(){
    return number;
}
public double Distance (double x, double y){
    double distance = sqrt((x-axisx)*(x-axisx)+(y-axisy)*(y-axisy));
    return distance;
}

}
