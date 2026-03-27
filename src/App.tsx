import { lazy, Suspense } from "react";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import "./App.css";

const CharacterModel = lazy(() => import("./components/Character"));
const MainContainer = lazy(() => import("./components/MainContainer"));
import { LoadingProvider } from "./context/LoadingProvider";

const ProjectDetail = lazy(() => import("./pages/ProjectDetail"));

const App = () => {
  return (
    <BrowserRouter>
      <LoadingProvider>
        <Routes>
          <Route path="/" element={
            <Suspense>
              <MainContainer>
                <Suspense>
                  <CharacterModel />
                </Suspense>
              </MainContainer>
            </Suspense>
          } />
          <Route path="/projects/:id" element={
            <Suspense fallback={<div style={{color: 'white', padding: '50px'}}>Loading project...</div>}>
              <ProjectDetail />
            </Suspense>
          } />
        </Routes>
      </LoadingProvider>
    </BrowserRouter>
  );
};

export default App;
