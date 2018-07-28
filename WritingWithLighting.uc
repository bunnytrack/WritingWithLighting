class WritingWithLighting extends Mutator config(WritingWithLighting);

var config string Characters[46];
var bool  FacingY, NegativeX, NegativeY;
var int   CharacterWidth, LightSpacing;
var float ScaledDS;
var vector CurrentLocation, CurrentRotation;

// -----------------
// to-do:
// -----------------
// • raise all lights: foreach Lights { CurrentLocation.Z += 100 }
// • change colours on the fly and/or have animated texture cycling through fabulous colours
// • remove invalid chars from user string at the beginning, to avoid offsetting invalid chars

/**function PreBeginPlay() {
	Level.Game.BaseMutator.AddMutator(self);
}

simulated event PostBeginPlay() {
	Super.PostBeginPlay();

	Log("");
	Log("+--------------------------------------------------------------------------+");
	Log("| WritingWithLighting                                                      |");
	Log("| ------------------------------------------------------------------------ |");
	Log("| Author:      Sapphire                                                    |");
	Log("| Version:     2018-07-14                                                  |");
	Log("| ------------------------------------------------------------------------ |");
	Log("| Released under the Creative Commons Attribution-NonCommercial-ShareAlike |");
	Log("| license. See https://creativecommons.org/licenses/by-nc-sa/4.0/          |");
	Log("+--------------------------------------------------------------------------+");
}*/

function Mutate(string MutateString, PlayerPawn Sender) {
	local int    i;
	local string UserInput, UserInputChar, CharacterData;

	if (Sender.bAdmin) {
		// Remove "WritingWithLighting" from MutateString and trim whitespace
		UserInput = Caps(Trim(Mid(MutateString, 19)));

		switch (UserInput) {
			case "DESTROY":
				DestroyLights();
				break;

			default:
				if (UserInput != "") {
					// Character config.
					// to-do: move to mutate string
					LightSpacing   = 10;
					CharacterWidth = LightSpacing * 10;
					ScaledDS       = LightSpacing * 0.03;

					// Initially set to false, these will be used later to determine the message direction
					FacingY   = false;
					NegativeY = false;
					NegativeX = false;

					// Get current rotation (used to determine which direction (X/Y) to write the message)
					CurrentRotation = vector(Sender.ViewRotation);

					// Get current location (used to determine where to spawn the lights)
					CurrentLocation = Sender.Location;

					// Raise the current location so the message isn't buried in the floor
					CurrentLocation.Z += CharacterWidth;

					// Determine which axis/direction to use
					if (CurrentRotation.Y >= 0.5 || CurrentRotation.Y <= -0.5) {

						FacingY = true;

						if (CurrentRotation.Y <= -0.5) {
							NegativeY = true;
						}

					} else {

						FacingY = false;

						if (CurrentRotation.X <= -0.5) {
							NegativeX = true;
						}

					}

					// Offset the starting X or Y position so that the player is at the middle of the message
					// Also move the starting position forwards so the message spawns slightly in front of the player
					if (FacingY) {

						if (NegativeY) {
							CurrentLocation.X -= Len(UserInput) / 2 * CharacterWidth;
							CurrentLocation.Y -= CharacterWidth * 2;
						} else {
							CurrentLocation.X += Len(UserInput) / 2 * CharacterWidth;
							CurrentLocation.Y += CharacterWidth * 2;

						}

					} else {

						if (NegativeX) {
							CurrentLocation.X -= CharacterWidth * 2;
							CurrentLocation.Y += Len(UserInput) / 2 * CharacterWidth;
						} else {
							CurrentLocation.X += CharacterWidth * 2;
							CurrentLocation.Y -= Len(UserInput) / 2 * CharacterWidth;
						}

					}

					// Iterate through each character of the user input string
					for (i = 0; i < Len(UserInput); i++) {
						UserInputChar = Mid(UserInput, i, 1);

						if (UserInputChar == " ") {
							// Draw a "space" by incrementing the current location by the width of one character
							if (FacingY) {
								CurrentLocation.X -= CharacterWidth;
							} else {
								CurrentLocation.Y += CharacterWidth;
							}

						} else {
							CharacterData = GetCharacterData(UserInputChar);

							// Skip invalid characters
							if (CharacterData != "") {
								DrawFromCoords(CharacterData);

								// Only increment the current location if there's another character to follow
								if (i < Len(UserInput)) {
									if (FacingY) {
										if (NegativeY) {
											CurrentLocation.X += CharacterWidth;
										} else {
											CurrentLocation.X -= CharacterWidth;
										}
									} else {
										if (NegativeX) {
											CurrentLocation.Y -= CharacterWidth;
										} else {
											CurrentLocation.Y += CharacterWidth;
										}
									}
								}
							}
						}
					}
				}
			break;
		}
	}
}

// Returns coordinates for a given character
// e.g. "A" -> 3,0|4,0|5,0|etc.
function string GetCharacterData(string Character) {
	local int    i;
	local string CharacterMapSearch, Coordinates;

	for (i = 0; i < ArrayCount(Characters); i++) {
		CharacterMapSearch = Left(Characters[i], 1);

		if (Character == CharacterMapSearch) {
			Coordinates = Mid(Characters[i], 2);
		}
	}

	return Coordinates;
}

// Summon lights at each point in a given set of coordinates
// e.g. "3,0|4,0" summons lights at X3/Z0, X4/Z0, etc.
function DrawFromCoords(string Coords) {
	local bool         bEndReached;
	local int          X, Z, Boundary;
	local string       CoordPair;
	local TranslocGlow L;
	local vector       LightLocation;

	bEndReached = false;

	while (!bEndReached) {
		LightLocation = CurrentLocation;
		Boundary      = InStr(Coords, "|");

		if (Boundary == -1) {
			CoordPair   = Coords;
			bEndReached = true;
		} else {
			CoordPair = Left(Coords, Boundary);
			Coords    = Mid(Coords, Boundary + 1);
		}

		X = int(SplitCoord(CoordPair, "X"));
		Z = int(SplitCoord(CoordPair));

		if (FacingY) {
			if (NegativeY) {
				LightLocation.X += X * LightSpacing;
			} else {
				LightLocation.X -= X * LightSpacing;
			}
		} else {
			if (NegativeX) {
				LightLocation.Y -= X * LightSpacing;
			} else {
				LightLocation.Y += X * LightSpacing;
			}
		}

		LightLocation.Z -= Z * LightSpacing;

		L = Spawn(class'TranslocGlow');
		L.SetLocation(LightLocation);
		L.DrawScale = ScaledDS;
		L.Tag       = 'BTNetGlow';
	}
}

// Splits a pair of comma-separated coordiantes and returns the value for a given axis
// e.g. "3,0" X axis -> 3
function string SplitCoord(string CoordPair, optional string Axis) {
	local int i;

	while (Mid(CoordPair, i, 1) != ",") {
		i++;
	}

	if (Axis == "X") {
		return Left(CoordPair, i);
	} else {
		return Mid(CoordPair, i + 1);
	}
}


// Destroy all custom lights
function DestroyLights() {
	local TranslocGlow L;

	foreach AllActors(Class'TranslocGlow', L, 'BTNetGlow') {
		L.Destroy();
	}
}


// String trimming functions
// Available from https://wiki.beyondunreal.com/Legacy:Useful_String_Functions
static final function string LTrim(coerce string S) {
	while (Left(S, 1) == " ") {
		S = Right(S, Len(S) - 1);
	}
	return S;
}

static final function string RTrim(coerce string S) {
	while (Right(S, 1) == " ") {
		S = Left(S, Len(S) - 1);
	}
	return S;
}

static final function string Trim(coerce string S) {
	return LTrim(RTrim(S));
}