/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package converttopo;
import java.io.*;
/**
 *
 * @author wens
 */
public class Converttopo {

    /**
     * @param args the command line arguments
     */
    public static void main(String[] args) throws IOException {
        File file = new File("topo.txt");
        File filew = new File("topoconverted.txt");
        try{
                    FileReader inOne = new FileReader(file);
                    BufferedReader inTwo = new BufferedReader(inOne);
                    FileWriter outOne1 = new FileWriter(filew);
                    BufferedWriter outTwo1 = new BufferedWriter(outOne1);
                    String s1 = null;
                    int i=0;
                    while ((s1 = inTwo.readLine()) != null){
                        System.out.println(s1);
                        s1 = s1.replace(',', ' ');
                        outTwo1.write(i+" "+s1);
                        outTwo1.newLine();
                        outTwo1.flush();
                        i++;
                    }
                    inTwo.close();
                    inOne.close();
                    outTwo1.close();
                    outOne1.close();
        }catch(IOException e){
            System.out.println(e);
        }
        
    }
    
}
