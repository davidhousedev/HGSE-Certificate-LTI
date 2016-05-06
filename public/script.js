/**
 * This function is implemented in order to allow text to be centered in a PDF.
 * The feature is implemented by jsPDF but is not currently working as of 5/5/2016.
 */
    (function(API){
    API.myText = function(txt, options, x, y) {
        options = options ||{};
        /* Use the options align property to specify desired text alignment
         * Param x will be ignored if desired text alignment is 'center'.
         * Usage of options can easily extend the function to apply different text 
         * styles and sizes 
        */
        if( options.align == "center" ){
            // Get current font size
            var fontSize = this.internal.getFontSize();

            // Get page width
            var pageWidth = this.internal.pageSize.width;

            // Get the actual text's width
            /* You multiply the unit width of your string by your font size and divide
             * by the internal scale factor. The division is necessary
             * for the case where you use units other than 'pt' in the constructor
             * of jsPDF.
            */
            txtWidth = this.getStringUnitWidth(txt)*fontSize/this.internal.scaleFactor;

            // Calculate text's x coordinate
            x = ( pageWidth - txtWidth ) / 2;
        }

        // Draw text at x,y
        this.text(txt,x,y);
    }
})(jsPDF.API);

/**
 * Primary PDF creation function
 *
 * This will take in two objects as input and create a PDF populating text
 * according to properties within those objects.  
 *
 * This function relies upon jsPDF, a Javascript library used to create custom PDFs
 * according to library-specific function calls.
 * Github: https://github.com/MrRio/jsPDF
 * Editor Sandbox: http://mrrio.github.io/jsPDF/
 *
 */
function createCert(studentObject, courseObject){

/**
 * Initializes function-specific variables at the top for easy editing
 */

// Logo at the top of the PDF document
var hgseLogo = 'data:image/png;base64,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'
// Image of signature at bottom of page
var signature = courseObject.deptHeadSignature
// Name of student receiving certificate
var name = studentObject.fullName
// Number of credit hours awarded to student
var hoursWorked = studentObject.creditHours
// Title of completed course
var course = courseObject.courseTitle
// Name of signee
var signer = courseObject.deptHead
// Signee role
var signerRole = courseObject.deptHeadRole
    

var doc = new jsPDF(); // start writing new PDF


doc.setFont("times"); // sets font family for all text printed below this function
doc.setFontSize("22"); // sets font size for below text
doc.myText("Programs in Professional Education", {align: "center"},0,100); // prints centered text according to custom function
doc.setFontSize("15"); // changes font size for any text printed below this function
doc.myText("Acknowledges", {align: "center"}, 0, 120);

doc.setFontSize("30");
doc.setTextColor(170, 31, 52); // sets text color (r, g, b)
doc.myText(name, {align: "center"}, 0, 140);

doc.setFontSize("15");
doc.setTextColor(0);
// concatinates text with variable to make text display dynamic content
doc.myText("Completed " + hoursWorked + " Hours of Work in", {align: "center"}, 0, 160);

doc.setFontSize("28");
// splits course title into an array of strings according to page
// size and font size.
var courseTitle = doc.splitTextToSize(course, 180);
//To print centered, loop through array and print
//using doc.myText to print each string centered
var nextLine = 10; // creater spacing for the next line of text
for (i = 0; i < courseTitle.length.toString(); i++) {
    // prints a string from courseTitle array to center
    doc.myText(courseTitle[i], {align: "center"}, 0, (180 + (i * 10)))
    nextLine += 10; // for every new line, increase space to next line
}

// print date.  information may be able to be sent via LTI
// but as of 5/3/2016 I haven't done any testing
doc.setFontSize("15")
doc.myText("September - December 2015", {align: "center"}, 0, (180 + nextLine))



// create borders
doc.setLineWidth(1.5); //set line width before creating border
doc.rect(5, 5, 200, 286); //create border in PDF (x position, y position, width, height)
doc.setLineWidth(.5);
doc.rect(7, 7, 196, 282);

// add images
doc.addImage(hgseLogo, 'PNG', 15, 15, 180, 35.7); // add image to pdf (data URL variable, format, x, y, width, height)

// add signature
doc.addImage(signature, 'PNG', 30, 250, 50, 15.81)
doc.text(signer, 30, 270, 0, 300)
doc.text(signerRole, 30, 276, 0, 300)

// saves PDF
doc.save('ppe_cert.pdf')

}




/**
 * Implemented for testing
 */
 /*
function testRuby(person, course){

        var thing = new jsPDF();
        thing.myText(person.fullName, {align: "center"},0,100); // prints centered text according to custom function
        thing.myText(course.courseName, {align: "center"},0,200); // prints centered text according to custom function

        thing.save('Test.pdf');

    };

$('#rubyTest').click(function(){
    testRuby("fjsoeijf");
});
*/

$('#test').click(function(){
    alert("Hello, jQuery");
});