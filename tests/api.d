module tests.api;

import unit_threaded;
import cerealed;

void testType() {
    checkEqual(new Cerealiser().type, Cereal.Type.Write);
    checkEqual(new Decerealiser([1]).type, Cereal.Type.Read);
}
