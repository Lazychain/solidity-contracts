import React from "react";
import { Routes, Route } from "react-router-dom";
import Lottery from "../pages/Lottery";
import Home from "../pages/Home";

const AppRoutes: React.FC = () => {
  return (
    <Routes>
      <Route path="/" element={<Home />} />
      <Route path="/lottery" element={<Lottery />} />
    </Routes>
  );
};

export default AppRoutes;