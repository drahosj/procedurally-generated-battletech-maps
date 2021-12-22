<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:map="http://pqz.us/btmap"
    xmlns:math="http://exslt.org/math"
    xmlns:svg="http://www.w3.org/2000/svg"
    version="1.0">

    <xsl:output method="xml" indent="yes"/>
    <xsl:variable name="sideToSide" select="100"/>

    <xsl:variable name="pi" select="3.1415927"/>
    <xsl:variable name="apothem" select="$sideToSide div 2"/>
    <xsl:variable name="side" select="$apothem div math:sin($pi div 3)"/>
    <xsl:variable name="vertexToVertex" select="$side * 2"/>
    <xsl:variable name="strokeWidth" select="$sideToSide div 50"/>


    <xsl:template match="/map:map">
        <svg:svg height="22in" width="18in">
            <xsl:apply-templates/>
        </svg:svg>
    </xsl:template>

    <xsl:template match="map:hex">
        <xsl:variable 
            name="x0"
            select="floor((@column - 1) div 2)*3*$side + ((@column - 1) mod 2)*$side*1.5"/>
        <xsl:variable name="x1" select="$x0 + $side*0.5"/>
        <xsl:variable name="x2" select="$x0 + $side*1.5"/>
        <xsl:variable name="x3" select="$x0 + $side*2"/>

        <xsl:variable
            name="y1"
            select="@row*$sideToSide - (@column mod 2)*$apothem"/>
        <xsl:variable name="y0" select="$y1 - $apothem"/>
        <xsl:variable name="y2" select="$y1 + $apothem"/>

        <xsl:variable name="center" select="concat($x1 + $side div 2, ',', $y1)"/>

        <xsl:variable name="hue">
            <xsl:choose>
                <xsl:when test="map:woods = 'light'">98</xsl:when>
                <xsl:when test="map:woods = 'heavy'">98</xsl:when>
                <xsl:otherwise>63</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="sat">
            <xsl:choose>
                <xsl:when test="map:woods = 'light'">77</xsl:when>
                <xsl:when test="map:woods = 'heavy'">77</xsl:when>
                <xsl:otherwise>29</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="lumBase">
            <xsl:choose>
                <xsl:when test="map:woods = 'light'">30</xsl:when>
                <xsl:when test="map:woods = 'heavy'">10</xsl:when>
                <xsl:otherwise>29</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <xsl:variable name="lumStep">
            <xsl:choose>
                <xsl:when test="map:woods = 'light'">5</xsl:when>
                <xsl:when test="map:woods = 'heavy'">3</xsl:when>
                <xsl:otherwise>5</xsl:otherwise>
            </xsl:choose>
        </xsl:variable>


        <xsl:variable name="lum">
            <xsl:choose>
                <xsl:when test="map:level &gt; 0">
                    <xsl:value-of select="$lumBase + map:level * $lumStep"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$lumBase"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:variable>

        <svg:polygon 
            points="{$x0},{$y1} {$x1},{$y0} {$x2},{$y0} {$x3},{$y1} {$x2},{$y2} {$x1},{$y2}"
            fill="hsl({$hue}, {$sat}%, {$lum}%)" stroke="black" stroke-width="{$strokeWidth}" />

        <xsl:if test="map:path">
            <xsl:variable name="fill">#979797</xsl:variable>
            <xsl:choose>
                <xsl:when test="map:path = 'straight'">
                    <svg:polygon
                        points="{$x1},{$y2} {$x1},{$y0} {$x2},{$y0} {$x2},{$y2}"
                        transform="rotate({map:path/@orientation * 60}, {$center})"
                        fill="{$fill}" stroke="black"/>
                </xsl:when>
                <xsl:when test="map:path = 'left'">
                    <svg:path
                    d="M {$x1} {$y2} 
                    A {$side} {$side}, 0, 0, 0, {$x0} {$y1}
                    L {$x1} {$y0}
                    A {$side * 2} {$side * 2}, 0, 0, 1, {$x2} {$y2}
                    "
                        transform="rotate({map:path/@orientation * 60}, {$center})"
                        fill="{$fill}" stroke="black"/>
                </xsl:when>
                <xsl:when test="map:path = 'right'">
                    <svg:path
                    d="M {$x1} {$y2} 
                    A {$side * 2} {$side * 2}, 0, 0, 1, {$x2} {$y0}
                    L {$x3} {$y1}
                    A {$side} {$side}, 0, 0, 0, {$x2} {$y2}
                    "
                        transform="rotate({map:path/@orientation * 60}, {$center})"
                        fill="{$fill}" stroke="black"/>
                </xsl:when>
            </xsl:choose>
        </xsl:if>

        <xsl:if test="map:level &gt; 0">
            <svg:text x="{$x1 + $side div 2}" y="{$y2 - $apothem*0.3}" font-size="{$side div 4}" text-anchor="middle">
                LEVEL <xsl:value-of select="map:level"/>
            </svg:text>
        </xsl:if>

        <svg:text x="{$x1 + $side div 2}" y="{$y0 + $apothem*0.2}" font-size="{$side div 6}" text-anchor="middle">
            <xsl:value-of select="concat(format-number(@column, '00'), format-number(@row, '00'))"/>
        </svg:text>

        <xsl:if test="map:woods">
            <svg:text x="{$x1 + $side div 2}" y="{$y1 - $apothem*0.4}" font-size="{$side div 3}" text-anchor="middle">
                <xsl:value-of select="translate(map:woods, 'lighteavy', 'LIGHTEAVY')"/>
            </svg:text>
        </xsl:if>

        <svg:polygon 
            points="{$x0},{$y1} {$x1},{$y0} {$x2},{$y0} {$x3},{$y1} {$x2},{$y2} {$x1},{$y2}"
            fill="rgba(0,0,0,0)" stroke="black" stroke-width="{$strokeWidth}" />

    </xsl:template> 
</xsl:stylesheet>
