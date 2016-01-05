/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package javaconvertnoise;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;

/**
 *
 * @author wens
 */
public class Javaconvertnoise {

    /**
     * @param args the command line arguments
     */
    public static void main(String[] args) {
         File file = new File("radio-noise.txt");
        File filew = new File("radio-noiseconverted.txt");
        try{
                    FileReader inOne = new FileReader(file);
                    BufferedReader inTwo = new BufferedReader(inOne);
                    FileWriter outOne1 = new FileWriter(filew);
                    BufferedWriter outTwo1 = new BufferedWriter(outOne1);
                    String s1 = null;
                    int i = 0;
                    while ((s1 = inTwo.readLine()) != null){
                        System.out.println(s1);
                        double noise = Double.parseDouble(s1);
                        noise = noise -7; 
                        int noise1 = (int)noise;
                        outTwo1.write(Integer.toString(noise1));
                        outTwo1.newLine();
                        outTwo1.flush();
                        i++;
                        if(i >=20000){
                            break;
                        }
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
